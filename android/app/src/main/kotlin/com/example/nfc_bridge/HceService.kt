package com.example.nfc_bridge

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log

class HceService : HostApduService() {
    companion object {
        const val TAG = "HceService"
        var broadcastText: String = "Hello from Android NFC Bridge"
    }

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        Log.d(TAG, "Processing APDU command")

        // Calculate dynamic lengths
        val langCodeLength = 2 // 'en' language code
        val textBytes = broadcastText.toByteArray(Charsets.UTF_8)
        val payloadLength = 1 + langCodeLength + textBytes.size // status byte + lang code + text
        val ndefMessageLength = 1 + 1 + 1 + 1 + payloadLength // header flags + type length + payload length + type + payload

        // Build the NDEF response
        val response = ByteArray(ndefMessageLength + 3) // +3 for TLV tag, length, and terminator

        // NDEF Message wrapper
        response[0] = 0x03.toByte() // NDEF message TLV tag
        response[1] = ndefMessageLength.toByte() // length of the NDEF message

        // NDEF Record header
        response[2] = 0xD1.toByte() // Record header flags (MB=1, ME=1, CF=0, SR=1, IL=0, TNF=001)
        response[3] = 0x01.toByte() // Type length = 0x01 (one byte type field)
        response[4] = payloadLength.toByte() // Payload length
        response[5] = 0x54.toByte() // Type = 0x54 (ASCII 'T' — NDEF Text Record type)

        // Text Record payload
        response[6] = 0x02.toByte() // Status byte (Bit 7 = 0 (UTF-8 encoding), Bits 5-0 = 0x02 (language code length = 2))
        response[7] = 0x65.toByte() // Language code 'e' (0x65)
        response[8] = 0x6E.toByte() // Language code 'n' (0x6E)

        // Copy the broadcast text
        System.arraycopy(textBytes, 0, response, 9, textBytes.size)

        // Terminator TLV
        response[9 + textBytes.size] = 0xFE.toByte() // Terminator TLV

        // APDU success trailer
        val finalResponse = ByteArray(response.size + 2)
        System.arraycopy(response, 0, finalResponse, 0, response.size)
        finalResponse[finalResponse.size - 2] = 0x90.toByte() // Success status word SW1
        finalResponse[finalResponse.size - 1] = 0x00.toByte() // Success status word SW2

        Log.d(TAG, "Sending NDEF response: ${finalResponse.contentToString()}")
        return finalResponse
    }

    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "HCE service deactivated, reason: $reason")
    }
}