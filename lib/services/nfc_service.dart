/// [nfc_service.dart] — Handles all NFC hardware interactions.
/// Part of the nfc_bridge project.
/// Platform: iOS and Android
/// Depends on: flutter_nfc_kit, ndef, dart:io

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import '../models/nfc_data.dart';

class NfcService {
  static const MethodChannel _channel =
      MethodChannel('com.example.nfc_bridge/hce');

  /// Reads an NFC tag and returns parsed NfcData.
  /// Supports reading NDEF records: Text, URI, and MIME.
  Future<NfcData> readTag() async {
    try {
      // Start NFC session with a platform-specific alert message (iOS only)
      await FlutterNfcKit.poll(
          iosAlertMessage: "Hold your iPhone near the NFC tag");

      // Read NDEF records
      final records = await FlutterNfcKit.readNDEFRecords();

      // Check if we have records
      if (records.isEmpty) {
        throw Exception('No NDEF records found on tag');
      }

      // Get the first record
      final record = records.first;

      // Parse based on record type
      if (record is ndef.TextRecord) {
        return NfcData(
          type: NfcDataType.text,
          content: record.text ?? '',
        );
      } else if (record is ndef.UriRecord) {
        return NfcData(
          type: NfcDataType.uri,
          content: record.uri.toString(),
        );
      } else if (record is ndef.MimeRecord) {
        // Try to decode as text if it's json/xml/text, else just return info
        String content = "Binary Data";
        try {
          content = String.fromCharCodes(record.payload ?? []);
        } catch (_) {
          content = "Binary Data (${record.payload?.length ?? 0} bytes)";
        }

        return NfcData(
          type: NfcDataType.mime,
          content: content,
          mimeType: record.decodedType,
          rawPayload: record.payload,
        );
      } else {
        // Attempt to decode payload bytes as UTF-8 string for other record types
        String content = '';
        try {
          content = String.fromCharCodes(record.payload ?? []);
        } catch (_) {
          content = 'Unknown Data';
        }
        return NfcData(
          type: NfcDataType.unknown,
          content: content,
          rawPayload: record.payload,
        );
      }
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Failed to read NFC tag');
    } catch (e) {
      throw Exception('Failed to read NFC tag: $e');
    } finally {
      // Always finish the session to release the NFC controller
      await FlutterNfcKit.finish(iosAlertMessage: "Finished");
    }
  }

  /// Starts HCE broadcast on Android.
  /// Invokes the platform channel method 'startBroadcast'.
  Future<void> startHceBroadcast(String text) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('HCE broadcasting is not supported on iOS. '
          'iOS can only read NFC tags.');
    }

    try {
      await _channel.invokeMethod('startBroadcast', {'text': text});
    } on MissingPluginException {
      throw Exception('HCE plugin not found. Ensure the app is running on '
          'a physical Android device.');
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Failed to start HCE broadcast');
    }
  }

  /// Stops HCE broadcast on Android.
  Future<void> stopHceBroadcast() async {
    if (!Platform.isAndroid) {
      // No-op on iOS
      return;
    }

    try {
      await _channel.invokeMethod('stopBroadcast');
    } on MissingPluginException {
      throw Exception('HCE plugin not found. Ensure the app is running on '
          'a physical Android device.');
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Failed to stop HCE broadcast');
    }
  }
}
