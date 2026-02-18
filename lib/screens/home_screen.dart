/// [home_screen.dart] — Root screen. Shows mode toggle on Android,
/// read screen directly on iOS.
/// Part of the nfc_bridge project.
/// Platform: iOS and Android

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nfc_provider.dart';
import '../models/app_mode.dart';
import '../utils/platform_utils.dart';
import 'read_screen.dart';
import 'broadcast_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Bridge'),
      ),
      body: Consumer<NfcProvider>(
        builder: (context, provider, child) {
          if (isAndroid) {
            return Column(
              children: [
                // Mode toggle for Android
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SegmentedButton<AppMode>(
                    segments: const [
                      ButtonSegment(
                        value: AppMode.read,
                        label: Text('Read'),
                        icon: Icon(Icons.nfc),
                      ),
                      ButtonSegment(
                        value: AppMode.broadcast,
                        label: Text('Broadcast'),
                        icon: Icon(Icons.wifi_tethering),
                      ),
                    ],
                    selected: {provider.mode},
                    onSelectionChanged: (Set<AppMode> newSelection) {
                      if (newSelection.isNotEmpty) {
                        provider.setMode(newSelection.first);
                      }
                    },
                  ),
                ),
                // Show appropriate screen based on mode
                Expanded(
                  child: provider.mode == AppMode.read
                      ? const ReadScreen()
                      : const BroadcastScreen(),
                ),
              ],
            );
          } else {
            // iOS only supports read mode
            return const ReadScreen();
          }
        },
      ),
    );
  }
}
