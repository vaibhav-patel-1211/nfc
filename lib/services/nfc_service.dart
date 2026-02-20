/// [nfc_service.dart] — Handles all NFC hardware interactions.
/// Part of the nfc_bridge project.
import 'dart:io';
import 'dart:convert';
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

      // Prioritize Text records first, then MIME, then fallback to whatever is first.
      ndef.NDEFRecord? selectedRecord;
      for (var r in records) {
        if (r is ndef.TextRecord) {
          selectedRecord = r;
          break; // Text has highest priority
        }
      }

      if (selectedRecord == null) {
        for (var r in records) {
          if (r is ndef.MimeRecord) {
            selectedRecord = r;
            break; // Custom MIME records are secondary priority
          }
        }
      }

      // Fallback to the first record if our priorities weren't found
      final record = selectedRecord ?? records.first;

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
        String content = "Binary Data";

        // Explicitly decode our custom MIME type as a UTF-8 string,
        // since iOS CoreNFC occasionally struggles with generic extraction.
        if (record.decodedType == 'application/vnd.nfcbridge' &&
            record.payload != null) {
          try {
            content = utf8.decode(record.payload!);
          } catch (_) {
            content = String.fromCharCodes(record.payload!);
          }
        } else {
          try {
            content = utf8.decode(record.payload ?? []);
          } catch (_) {
            content = "Binary Data (${record.payload?.length ?? 0} bytes)";
          }
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
      if (e.message != null && e.message!.contains('NDEF not supported')) {
        throw Exception(
            'This NFC tag is empty, unformatted, or not NDEF compatible.');
      }
      throw Exception(e.message ?? 'Failed to read NFC tag');
    } catch (e) {
      if (e.toString().contains('NDEF not supported')) {
        throw Exception(
            'This NFC tag is empty, unformatted, or not NDEF compatible.');
      }
      throw Exception('Failed to read NFC tag: $e');
    } finally {
      // Always finish the session to release the NFC controller
      try {
        await FlutterNfcKit.finish(iosAlertMessage: "Finished");
      } catch (e) {
        // Ignore errors during finish, such as MissingPluginException on some Android setups
        print('Ignored error finishing NFC session: $e');
      }
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
