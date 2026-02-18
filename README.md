# NFC Bridge

## Overview
NFC Bridge is a Flutter application that reads NDEF tags on both iOS and Android platforms. On Android, it additionally uses Host Card Emulation (HCE) to emulate a tag so other devices can scan it. Unlike older implementations, this app does not use Android Beam which was removed in Android 10.

## Prerequisites
- Flutter stable channel (3.16.0 or later)
- Xcode 14+ (macOS only, for iOS builds)
- Android Studio with Android SDK API 31+
- Physical iOS device: iPhone 7 or later (iOS 13+)
- Physical Android device with NFC and HCE support (Android 12+)
- NFC simulators and emulators are NOT supported

## iOS Setup
1. Open ios/Runner.xcworkspace in Xcode (never open .xcodeproj)
2. Select the Runner target in the project navigator
3. Go to Signing & Capabilities tab
4. Click + Capability and add Near Field Communication Tag Reading
5. Confirm Runner.entitlements now contains the NFC formats key
6. Set minimum deployment target to iOS 13.0
7. Select your physical device as the build target
8. Run: flutter run

## Android Setup
1. Enable NFC on your Android device: Settings → Connected devices → NFC
2. Confirm the device supports HCE (most Android 5+ devices do)
3. Connect device via USB with USB debugging enabled
4. Run: flutter run

## Running the App
```
flutter run          # auto-detects connected device
flutter run -d <id>  # target a specific device
```

## How to Use

### iOS — Reading
Tap Scan Tag and hold the iPhone near any NDEF NFC tag.
The tag text appears on screen within seconds.

### Android — Reading
Same as iOS. Tap Scan Tag and hold near any NDEF NFC tag.

### Android — Broadcasting
1. Switch to Broadcast mode using the toggle at the top
2. Tap Start Broadcasting
3. The green pulsing dot confirms HCE is active
4. Hold another NFC-enabled phone (iOS or Android) near this device
5. The other phone scans this device as if it were a physical NFC tag
6. The preset broadcast text appears on the scanning device
7. Tap Stop Broadcasting when done

## Changing the Broadcast Text
Edit the kDefaultBroadcastText constant in lib/providers/nfc_provider.dart.
The text can be up to ~200 characters. A future update will add a
text field in the UI.

## Known Limitations
- Android Beam was removed in Android 10 and is not used in this app
- iOS cannot emulate NFC tags — the Broadcast mode does not exist on iOS
- NFC is not available in iOS Simulator or Android Emulator
- HCE requires the reader device to select our AID (F0010203040506);
  standard tag readers will select this automatically
- Some Android devices disable HCE when the screen is off

## Troubleshooting

**iOS: "NFC session failed" immediately**
Cause: NFC capability not added in Xcode.
Fix: Signing & Capabilities → add Near Field Communication Tag Reading.

**iOS: App builds but crashes on scan**
Cause: NFCReaderUsageDescription missing from Info.plist or entitlement
not in Runner.entitlements.
Fix: Verify both files contain the NFC keys shown in this README.

**Android: Broadcasting active but other device reads nothing**
Cause: Scanning device is not selecting the correct AID.
Fix: Ensure the scanning device is running this app or a standard
NDEF reader app. The AID F0010203040506 is proprietary — non-NFC-Bridge
readers may ignore it. Use a generic NDEF tag reading app to verify.

**Android: "NFC is not available or disabled"**
Cause: NFC is turned off on the device.
Fix: Settings → Connected devices → NFC → toggle on.

**Both: Tag scanned but shows empty result**
Cause: Tag is not NDEF formatted or contains a non-text record type.
Fix: Use an NFC tag writer app to write a plain Text record to the tag
before testing.
