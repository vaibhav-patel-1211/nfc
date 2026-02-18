/// [app_mode.dart] — Enum defining the two operating modes.
/// Part of the nfc_bridge project.
/// Platform: Android only (iOS always uses read mode)

enum AppMode {
  /// Read mode: scan physical NFC tags and display their text
  read,

  /// Broadcast mode: emulate an NFC tag via HCE (Android only)
  broadcast,
}
