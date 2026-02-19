/// [nfc_provider.dart] — State management for NFC operations.
/// Part of the nfc_bridge project.
/// Platform: iOS and Android
/// Depends on: provider, NfcService, AppMode

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/nfc_service.dart';
import '../services/file_server_service.dart';
import '../models/app_mode.dart';
import '../models/nfc_data.dart';

class NfcProvider extends ChangeNotifier {
  final NfcService _nfcService = NfcService();
  final FileServerService _fileServer = FileServerService();

  NfcData? lastRead; // last successfully read tag data
  String? errorMessage; // last error, null when no error
  bool isReading = false; // true while a scan is in progress
  bool isBroadcasting = false; // true while HCE is active
  AppMode mode = AppMode.read; // current operating mode
  File? selectedFile; // Currently selected file for broadcast
  String? selectedFileName; // Name of the selected file for UI display

  static const String kDefaultBroadcastText = 'https://flutter.dev';
  String broadcastText = kDefaultBroadcastText;

  /// Updates the text to be broadcasted
  void setBroadcastText(String text) {
    // If text is changed manually, clear the file server
    if (selectedFile != null && text != _fileServer.getServerUrl()) {
      _fileServer.stopServer();
      selectedFile = null;
      selectedFileName = null;
    }
    broadcastText = text;
    notifyListeners();
  }

  /// Sets the current app mode
  void setMode(AppMode newMode) {
    // If switching from broadcast to read while broadcasting, stop broadcast first
    if (isBroadcasting && newMode == AppMode.read) {
      stopBroadcast();
    }

    mode = newMode;
    errorMessage = null;
    notifyListeners();
  }

  /// Starts reading an NFC tag.
  /// Used by iOS (natively) and Android (foreground dispatch).
  Future<void> startRead() async {
    // Prevent double tap
    if (isReading) return;

    isReading = true;
    errorMessage = null;
    notifyListeners();

    try {
      lastRead = await _nfcService.readTag();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isReading = false;
      notifyListeners();
    }
  }

  /// Toggles broadcast state (Android only).
  Future<void> toggleBroadcast() async {
    if (isBroadcasting) {
      await stopBroadcast();
    } else {
      await startBroadcast();
    }
  }

  /// Starts HCE broadcast (Android only).
  /// Sets up the platform channel to respond to APDU commands.
  Future<void> startBroadcast() async {
    errorMessage = null;
    notifyListeners();

    try {
      await _nfcService.startHceBroadcast(broadcastText);
      isBroadcasting = true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      isBroadcasting = false;
    }

    notifyListeners();
  }

  /// Stops HCE broadcast (Android only).
  Future<void> stopBroadcast() async {
    try {
      await _nfcService.stopHceBroadcast();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isBroadcasting = false;
      notifyListeners();
    }
  }

  /// Picking a file and starting the server.
  /// Launches a file picker, starts a local HTTP server, and updates the broadcast text to the file's URL.
  Future<void> pickFile() async {
    try {
      // Request location permission (required for IP address on Android 12+)
      if (Platform.isAndroid) {
        await Permission.location.request();
      }

      // Pick any file type
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        selectedFile = File(result.files.single.path!);
        selectedFileName = result.files.single.name;

        // Start server and get URL
        final url = await _fileServer.startServer(selectedFile!);

        // Update broadcast text
        broadcastText = url;
        errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "File Server Error: $e";
      selectedFile = null;
      selectedFileName = null;
      _fileServer.stopServer();
      notifyListeners();
    }
  }
}
