/// [nfc_service.dart] — Handles all NFC hardware interactions.
/// Part of the nfc_bridge project.
/// Platform: iOS and Android
/// Depends on: flutter_nfc_kit, ndef, dart:io

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcService {
  static const MethodChannel _channel =
      MethodChannel('com.example.nfc_bridge/hce');

  /// Reads an NFC tag and returns its text content
  Future<String> readTag() async {
    try {
      // Start NFC session
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

      // Check if it's a TextRecord
      if (record is ndef.TextRecord) {
        return record.text ?? '';
      } else {
        // Attempt to decode payload bytes as UTF-8 string
        try {
          return String.fromCharCodes(record.payload as Iterable<int>);
        } catch (e) {
          throw Exception('Tag does not contain a text record');
        }
      }
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Failed to read NFC tag');
    } catch (e) {
      throw Exception('Failed to read NFC tag: $e');
    } finally {
      // Always finish the session
      await FlutterNfcKit.finish(iosAlertMessage: "Finished");
    }
  }

  /// Starts HCE broadcast on Android
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

  /// Stops HCE broadcast on Android
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
