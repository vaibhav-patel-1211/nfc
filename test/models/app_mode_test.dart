import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_bridge/models/app_mode.dart';
import 'package:nfc_bridge/providers/nfc_provider.dart';

void main() {
  group('AppMode', () {
    test('AppMode has exactly two values', () {
      expect(AppMode.values.length, 2);
      expect(AppMode.values, contains(AppMode.read));
      expect(AppMode.values, contains(AppMode.broadcast));
    });

    test('default mode in NfcProvider is AppMode.read', () {
      final provider = NfcProvider();
      expect(provider.mode, AppMode.read);
    });
  });
}
