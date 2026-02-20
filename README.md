# NFC Bridge

**NFC Bridge** is a Flutter application that reads NDEF tags on both iOS and Android platforms. On Android, it additionally uses Host Card Emulation (HCE) to emulate a tag so other devices can scan it. Unlike older implementations, this app does not use Android Beam, which was removed in Android 10.

## Features

-   **Cross-Platform NFC Reading:** Read NDEF formatted tags seamlessly on both iOS and Android.
-   **Android HCE Broadcasting:** Emulate an NFC tag on Android to securely broadcast text and URLs to other devices.
-   **Custom MIME Security:** Intercepts automatic Android browser pop-ups by wrapping data in a custom `application/vnd.nfcbridge` format, keeping the workflow strictly inside the app.
-   **iOS Compatibility:** Enforces true UTF-8 decoding on iOS CoreNFC to perfectly parse custom MIME records and strings from Android emitters.
-   **Modern Implementation:** Uses `flutter_nfc_kit` and native platform integrations.

---

## Prerequisites

Ensure you have the following installed and set up:

-   **Flutter SDK**: Stable channel (3.16.0 or later recommended).
-   **Android Development**:
    -   Android Studio with Android SDK API 31+.
    -   Physical Android device with NFC and HCE support (Android 12+ recommended).
    -   **Note:** Emulators *cannot* simulate NFC hardware.
-   **iOS Development** (macOS only):
    -   Xcode 14+.
    -   Physical iOS device (iPhone 7 or later, iOS 13+).
    -   Apple Developer Account (required for NFC capabilities).
    -   **Note:** Simulators *cannot* simulate NFC hardware.

---

## Project Structure

A quick overview of the key directories and files:

-   `lib/`: Contains the Dart code for the Flutter application.
    -   `main.dart`: Entry point of the application.
    -   `providers/nfc_provider.dart`: Manages state and NFC logic.
-   `android/`: Native Android project files.
    -   `app/src/main/AndroidManifest.xml`: Configures permissions and services.
    -   `app/src/main/res/xml/apdu_service.xml`: Defines the HCE service configuration.
-   `ios/`: Native iOS project files.
    -   `Runner/Info.plist`: Configures usage descriptions and capabilities.
    -   `Runner/Runner.entitlements`: Enables NFC capabilities.

---

## Setup & Configuration

This project requires specific native configuration to work correctly. Below are the steps and the specific changes made to the default Flutter template.

### Android Setup

1.  **Enable Developer Options & USB Debugging** on your Android device.
2.  **Enable NFC** in your device settings.
3.  **Verify HCE Support**: Most modern Android devices support it.

<details>
<summary><strong>View Android Configuration Changes</strong></summary>

The following changes are required in the `android` directory:

#### `android/app/src/main/AndroidManifest.xml`

Added permissions, feature requirements, intent filters for NDEF discovery, and the HCE service declaration.

```xml
<manifest ...>
    <!-- NFC Permissions -->
    <uses-permission android:name="android.permission.NFC" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <!-- NFC Features -->
    <uses-feature android:name="android.hardware.nfc" android:required="true" />
    <uses-feature android:name="android.hardware.nfc.hce" android:required="false" />

    <application ...>
        ...
        <!-- NDEF Discovery Intent Filters -->
        <intent-filter>
            <action android:name="android.nfc.action.NDEF_DISCOVERED" />
            <category android:name="android.intent.category.DEFAULT" />
            <data android:mimeType="text/plain" />
        </intent-filter>

        <intent-filter>
            <action android:name="android.nfc.action.NDEF_DISCOVERED" />
            <category android:name="android.intent.category.DEFAULT" />
            <data android:scheme="https" />
        </intent-filter>

        <!-- Fallback Tag Discovery -->
        <intent-filter>
            <action android:name="android.nfc.action.TAG_DISCOVERED" />
            <category android:name="android.intent.category.DEFAULT" />
        </intent-filter>

        <!-- HCE Service Declaration -->
        <service
            android:name=".HceService"
            android:exported="true"
            android:permission="android.permission.BIND_NFC_SERVICE">
            <intent-filter>
                <action android:name="android.nfc.cardemulation.action.HOST_APDU_SERVICE" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
            <meta-data
                android:name="android.nfc.cardemulation.host_apdu_service"
                android:resource="@xml/apdu_service" />
        </service>
    </application>
</manifest>
```

#### `android/app/src/main/res/xml/apdu_service.xml`

New file created to configure the Host APDU Service with a proprietary AID.

```xml
<?xml version="1.0" encoding="utf-8"?>
<host-apdu-service
  xmlns:android="http://schemas.android.com/apk/res/android"
  android:description="@string/hce_service_description"
  android:requireDeviceUnlock="false">
  <aid-group
    android:description="@string/hce_service_description"
    android:category="other">
    <!-- Proprietary AIDs -->
    <aid-filter android:name="D2760000850101" />
    <aid-filter android:name="D2760000850100" />
  </aid-group>
</host-apdu-service>
```

#### `android/app/build.gradle.kts`

Ensure the minimum SDK version is set to at least 31.

```kotlin
android {
    defaultConfig {
        minSdk = 31
        ...
    }
}
```

</details>

### iOS Setup

1.  Open `ios/Runner.xcworkspace` in Xcode.
2.  Select the **Runner** target -> **Signing & Capabilities**.
3.  Add the **Near Field Communication Tag Reading** capability.
4.  Ensure your **Provisioning Profile** supports NFC.

<details>
<summary><strong>View iOS Configuration Changes</strong></summary>

The following changes are required in the `ios` directory:

#### `ios/Runner/Info.plist`

Added usage description and supported NFC formats.

```xml
<dict>
    ...
    <key>NFCReaderUsageDescription</key>
    <string>NFC Bridge reads NFC tags to display their text content.</string>
    <key>com.apple.developer.nfc.readersession.formats</key>
    <array>
        <string>NDEF</string>
    </array>
</dict>
```

#### `ios/Runner/Runner.entitlements`

Ensure the entitlement for NDEF reading is present.

```xml
<dict>
    <key>com.apple.developer.nfc.readersession.formats</key>
    <array>
        <string>NDEF</string>
    </array>
</dict>
```

#### `ios/Podfile`
Ensure the platform version is set correctly.

```ruby
platform :ios, '13.0'
```

</details>

---

## How to Run

1.  Connect your physical device via USB.
2.  Run the following command in your terminal:

```bash
flutter run
```

If multiple devices are connected, list them and select one:

```bash
flutter devices
flutter run -d <device_id>
```

---

## Usage Guide

### Reading NFC Tags (iOS & Android)
1.  Tap **Scan Tag** on the app screen.
2.  Hold your device near an NDEF-formatted NFC tag (or an Android device in Broadcast mode).
3.  The app will instantly display the raw string or URL on the screen. It intentionally prevents external automatic browser redirects.

### Broadcasting (Android Only)
1.  Enter the text or URL you wish to share into the input field.
2.  Tap **Start Broadcasting**. The device is now acting as an NFC Tag.
3.  Touch another NFC-enabled device (iOS or Android) to the back of this device to instantly transmit the string.

---

## Troubleshooting & Limitations

-   **"NFC session failed" on iOS**: Ensure the "Near Field Communication Tag Reading" capability is added in Xcode.
-   **Broadcasting not working**: Ensure the receiving device supports reading the proprietary AID configured (`D2760000850101`).
-   **Empty Scan Result**: Ensure the tag is NDEF formatted and contains a text record.
-   **Screen Off**: Some Android devices disable HCE when the screen is off. Keep the device unlocked and screen on.

---

## CI/CD Pipeline

This project is configured for **Codemagic** to automate builds.

-   **Config File**: `codemagic.yaml`
-   **Workflows**:
    -   `ios-workflow`: Builds the iOS app (Release mode, unsigned).
-   **Artifacts**: Generates `.app` bundles for iOS.

---
