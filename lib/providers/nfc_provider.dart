/// [nfc_provider.dart] — State management for NFC operations.
/// Part of the nfc_bridge project.
/// Platform: iOS and Android
/// Depends on: provider, NfcService, AppMode

import 'package:flutter/foundation.dart';
import '../services/nfc_service.dart';
import '../models/app_mode.dart';
import '../models/nfc_data.dart';

class NfcProvider extends ChangeNotifier {
  final NfcService _nfcService = NfcService();
  NfcData? lastRead; // last successfully read tag data
  String? errorMessage; // last error, null when no error
  bool isReading = false; // true while a scan is in progress
  bool isBroadcasting = false; // true while HCE is active
  AppMode mode = AppMode.read; // current operating mode

  static const String kDefaultBroadcastText = 'https://flutter.dev';
  String broadcastText = kDefaultBroadcastText;

  /// Updates the text to be broadcasted
  void setBroadcastText(String text) {
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
}
