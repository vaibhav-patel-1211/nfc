/// [broadcast_screen.dart] — UI for HCE tag broadcasting (Android only).
/// Part of the nfc_bridge project.
/// Platform: Android only
///
/// IMPORTANT: This screen must never be shown on iOS.
/// iOS does not support NFC tag emulation.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nfc_provider.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize with current provider text
    final provider = Provider.of<NfcProvider>(context, listen: false);
    _textController = TextEditingController(text: provider.broadcastText);
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NfcProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Content Input/Display Section ---
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            'Broadcast Content',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // If broadcasting, show the static text being broadcasted
                          if (provider.isBroadcasting)
                            Text(
                              provider.broadcastText,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            )
                          else
                            // If not broadcasting, allow editing
                            Column(
                              children: [
                                // --- Text Input ---
                                TextField(
                                  controller: _textController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter text or URL',
                                    border: OutlineInputBorder(),
                                  ),
                                  textAlign: TextAlign.center,
                                  onChanged: (value) {
                                    provider.setBroadcastText(value);
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Broadcast Toggle Button ---
                  SizedBox(
                    width: 220,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        provider.isBroadcasting
                            ? Icons.wifi_tethering_off
                            : Icons.wifi_tethering,
                      ),
                      label: Text(
                        provider.isBroadcasting
                            ? 'Stop Broadcasting'
                            : 'Start Broadcasting',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            provider.isBroadcasting ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (!provider.isBroadcasting) {
                          // Hide keyboard and sync text
                          FocusScope.of(context).unfocus();
                          provider.setBroadcastText(_textController.text);
                        }
                        provider.toggleBroadcast();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Status Indicator ---
                  if (provider.isBroadcasting)
                    Column(
                      children: [
                        FadeTransition(
                          opacity: _controller,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Broadcasting active',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.green,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hold this phone near another NFC device to share',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Broadcasting Off',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),

                  // --- Error Display ---
                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Card(
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
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
