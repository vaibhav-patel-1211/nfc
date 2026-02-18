package com.example.nfc_bridge

import android.content.ComponentName
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.nfc_bridge/hce"
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startBroadcast" -> startBroadcast(call, result)
                "stopBroadcast" -> stopBroadcast(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun startBroadcast(call: MethodCall, result: Result) {
        try {
            // Extract text from arguments
            val args = call.arguments as Map<*, *>
            val text = args["text"] as String

            // Validate NFC adapter
            val nfcAdapter = NfcAdapter.getDefaultAdapter(this)
            if (nfcAdapter == null || !nfcAdapter.isEnabled) {
                result.error("NFC_UNAVAILABLE", "NFC is not available or disabled on this device", null)
                return
            }

            // Set broadcast text
            HceService.broadcastText = text

            // Enable HceService component
            val componentName = ComponentName(this, HceService::class.java)
            packageManager.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )

            result.success("Broadcasting started")
        } catch (e: Exception) {
            result.error("START_BROADCAST_FAILED", e.message, null)
        }
    }

    private fun stopBroadcast(result: Result) {
        try {
            // Disable HceService component
            val componentName = ComponentName(this, HceService::class.java)
            packageManager.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )

            result.success("Broadcasting stopped")
        } catch (e: Exception) {
            result.error("STOP_BROADCAST_FAILED", e.message, null)
        }
    }
}