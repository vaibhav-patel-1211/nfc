/// [read_screen.dart] — UI for reading NFC tags.
/// Part of the nfc_bridge project.
/// Platform: iOS and Android

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nfc_provider.dart';

class ReadScreen extends StatelessWidget {
  const ReadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NfcProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scan button
                SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.nfc),
                    label: const Text('Scan Tag'),
                    onPressed: provider.isReading ? null : provider.startRead,
                  ),
                ),
                const SizedBox(height: 32),

                // Loading state
                if (provider.isReading)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Hold device near NFC tag...'),
                    ],
                  ),

                // Result card
                if (provider.lastRead != null)
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 32),
                          Text('Tag Content',
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 8),
                          Text(
                            provider.lastRead!,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Error state
                if (provider.errorMessage != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 32),
                          Text(
                            provider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
