package com.example.nfc_bridge

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

import java.util.Arrays
import java.net.URLEncoder

class HceService : HostApduService() {
    companion object {
        const val TAG = "HceService"

        // --- CONSTANTS ---
        private val APDU_SELECT_AID = hexStringToByteArray("00A4040007D276000085010100")
        private val CC_FILE_ID = hexStringToByteArray("E103")
        private val NDEF_FILE_ID = hexStringToByteArray("E104")

        // Status Words
        private val SW_SUCCESS = hexStringToByteArray("9000")
        private val SW_FILE_NOT_FOUND = hexStringToByteArray("6A82")
        private val SW_INS_NOT_SUPPORTED = hexStringToByteArray("6D00")
        private val SW_CLA_NOT_SUPPORTED = hexStringToByteArray("6E00")
        private val SW_WRONG_P1P2 = hexStringToByteArray("6B00")
        private val SW_WRONG_LENGTH = hexStringToByteArray("6700")

        // Capability Container (CC) File
        // MLe (Max R-APDU size): 00FF (255 bytes)
        // Max NDEF Size: 0400 (1024 bytes) - Reduced from FFFE to support old devices
        // Write Access: FF (Read Only) to prevent reader OS from attempting writes and aborting
        private val CC_FILE = hexStringToByteArray("000F2000FF00FF0406E104040000FF")

        var broadcastText: String = "Hello from Android NFC Bridge"
            set(value) {
                field = value
                updateCachedNdefMessage()
            }

        private var cachedNdefMessage: ByteArray = ByteArray(0)

        init {
             updateCachedNdefMessage()
        }

        private fun hexStringToByteArray(s: String): ByteArray {
            val len = s.length
            val data = ByteArray(len / 2)
            for (i in 0 until len step 2) {
                data[i / 2] = ((Character.digit(s[i], 16) shl 4) + Character.digit(s[i + 1], 16)).toByte()
            }
            return data
        }

        // --- NDEF GENERATION ---
        private fun updateCachedNdefMessage() {
            try {
                val text = broadcastText

                // We broadcast everything as a custom MIME type to prevent Android from opening the browser
                val mimeType = "application/vnd.nfcbridge"
                val typeBytes = mimeType.toByteArray(Charsets.US_ASCII)
                val payloadBytes = text.toByteArray(Charsets.UTF_8)

                val typeLen = typeBytes.size
                val payloadLen = payloadBytes.size
                val isShortRecord = payloadLen <= 255

                // Header: MB=1, ME=1, CF=0, SR=?, IL=0, TNF=2 (MIME Media)
                val headerByte = if (isShortRecord) 0xD2 else 0xC2

                // Record Overhead: Header(1) + TypeLen(1) + PayloadLen(1 or 4) + TypeBytes
                val recordOverhead = 1 + 1 + (if (isShortRecord) 1 else 4) + typeLen
                val totalLen = recordOverhead + payloadLen

                // NDEF File: [Length (2 bytes)] + [NDEF Message]
                val fileContent = ByteArray(2 + totalLen)

                // File Length
                fileContent[0] = ((totalLen shr 8) and 0xFF).toByte()
                fileContent[1] = (totalLen and 0xFF).toByte()

                var idx = 2
                fileContent[idx++] = headerByte.toByte()
                fileContent[idx++] = typeLen.toByte()

                if (isShortRecord) {
                    fileContent[idx++] = payloadLen.toByte()
                } else {
                    fileContent[idx++] = ((payloadLen shr 24) and 0xFF).toByte()
                    fileContent[idx++] = ((payloadLen shr 16) and 0xFF).toByte()
                    fileContent[idx++] = ((payloadLen shr 8) and 0xFF).toByte()
                    fileContent[idx++] = (payloadLen and 0xFF).toByte()
                }

                // Append Type (MIME string)
                System.arraycopy(typeBytes, 0, fileContent, idx, typeLen)
                idx += typeLen

                // Append Payload
                System.arraycopy(payloadBytes, 0, fileContent, idx, payloadLen)

                cachedNdefMessage = fileContent

            } catch (e: Exception) {
                // Log error or handle silently
            }
        }
    }

    // --- STATE MACHINE ---
    private var selectedFile: ByteArray? = null

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        if (commandApdu.size < 4) return SW_INS_NOT_SUPPORTED

        val cla = commandApdu[0]
        val ins = commandApdu[1]
        val p1 = commandApdu[2]
        val p2 = commandApdu[3]

        if (cla != 0x00.toByte()) return SW_CLA_NOT_SUPPORTED

        if (ins == 0xA4.toByte()) {
            return handleSelect(commandApdu, p1, p2)
        }

        if (ins == 0xB0.toByte()) {
            return handleReadBinary(commandApdu, p1, p2)
        }

        return SW_INS_NOT_SUPPORTED
    }

    private fun handleSelect(apdu: ByteArray, p1: Byte, p2: Byte): ByteArray {
        // SELECT by AID (P1=04, P2=00)
        if (p1 == 0x04.toByte() && p2 == 0x00.toByte()) {
            if (apdu.size >= 5 + 7) {
                 selectedFile = null
                 return SW_SUCCESS
            }
        }

        // SELECT by File ID (P1=00)
        // Standard says P2=0x0C (First or only occurrence), but we accept 0x00 to be safe.
        if (p1 == 0x00.toByte() && (p2 == 0x0C.toByte() || p2 == 0x00.toByte())) {
             if (apdu.size < 7) return SW_WRONG_LENGTH
             val fileId = Arrays.copyOfRange(apdu, 5, 7)

             if (Arrays.equals(fileId, CC_FILE_ID)) {
                 selectedFile = CC_FILE_ID
                 return SW_SUCCESS
             }
             if (Arrays.equals(fileId, NDEF_FILE_ID)) {
                 selectedFile = NDEF_FILE_ID
                 return SW_SUCCESS
             }
             return SW_FILE_NOT_FOUND
        }

        return SW_WRONG_P1P2
    }

    private fun handleReadBinary(apdu: ByteArray, p1: Byte, p2: Byte): ByteArray {
        if (selectedFile == null) return SW_INS_NOT_SUPPORTED

        val offset = ((p1.toInt() and 0xFF) shl 8) or (p2.toInt() and 0xFF)

        var le = 0
        if (apdu.size >= 5) {
             le = apdu[4].toInt() and 0xFF
        }

        val data = if (Arrays.equals(selectedFile, CC_FILE_ID)) CC_FILE else cachedNdefMessage

        // Strict boundary check
        if (offset < 0 || offset >= data.size) {
            return SW_WRONG_P1P2
        }

        var lenToRead = le
        if (lenToRead == 0) {
            lenToRead = data.size - offset
            if (lenToRead > 255) lenToRead = 255 // MLe cap
        }

        lenToRead = Math.min(lenToRead, data.size - offset)

        val response = ByteArray(lenToRead + 2)
        System.arraycopy(data, offset, response, 0, lenToRead)

        // Append Status Words (90 00)
        response[lenToRead] = 0x90.toByte()
        response[lenToRead + 1] = 0x00.toByte()

        return response
    }

    override fun onDeactivated(reason: Int) {
        selectedFile = null
    }
}
