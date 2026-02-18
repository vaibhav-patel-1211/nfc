import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_bridge/providers/nfc_provider.dart';
import 'package:nfc_bridge/models/app_mode.dart';

void main() {
  group('NfcProvider', () {
    late NfcProvider provider;

    setUp(() {
      provider = NfcProvider();
    });

    test('initial state is correct', () {
      expect(provider.lastRead, null);
      expect(provider.errorMessage, null);
      expect(provider.isReading, false);
      expect(provider.isBroadcasting, false);
      expect(provider.mode, AppMode.read);
      expect(provider.broadcastText, NfcProvider.kDefaultBroadcastText);
    });

    test('setMode updates mode correctly', () {
      provider.setMode(AppMode.broadcast);
      expect(provider.mode, AppMode.broadcast);

      provider.setMode(AppMode.read);
      expect(provider.mode, AppMode.read);
    });

    test('setMode clears error message', () {
      provider.errorMessage = 'Test error';
      provider.setMode(AppMode.broadcast);
      expect(provider.errorMessage, null);
    });

    // Note: Testing async methods like startRead, startBroadcast, etc.
    // would require more complex mocking of the MethodChannel and platform channels
    // which is beyond the scope of this basic test setup
  });
}
