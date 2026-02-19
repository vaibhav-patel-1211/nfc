/// [app_mode.dart] — Enum defining the two operating modes for NFC operations.
/// Part of the nfc_bridge project.
/// Platform: Android only (iOS always uses read mode)
///
/// This enum represents the two primary modes of operation for the NFC Bridge application:
/// - [read]: Scanning and reading physical NFC tags to extract their content
/// - [broadcast]: Emulating an NFC tag via Host Card Emulation (HCE) to broadcast content
///
/// Note: iOS platform only supports read mode as Apple does not provide HCE APIs for
/// third-party applications. Android supports both modes.

enum AppMode {
  /// Read mode: scan physical NFC tags and display their text content.
  ///
  /// In this mode, the application uses the device's NFC reader to detect and read
  /// NFC tags. The content is then parsed and displayed to the user. This is the
  /// only mode available on iOS devices due to platform limitations.
  read,

  /// Broadcast mode: emulate an NFC tag via HCE (Host Card Emulation) to broadcast content.
  ///
  /// This mode is only available on Android devices. It allows the application to
  /// emulate an NFC tag and broadcast specified content when another NFC reader
  /// device is brought close to this device. The broadcast content can be text,
  /// URLs, or files served via a local HTTP server.
  broadcast,
}
