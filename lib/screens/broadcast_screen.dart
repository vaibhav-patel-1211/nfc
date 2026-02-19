/// [broadcast_screen.dart] — UI for HCE tag broadcasting (Android only).
/// Part of the nfc_bridge project.
/// Platform: Android only
///
/// IMPORTANT: This screen must never be shown on iOS.
/// iOS does not support NFC tag emulation.

import 'dart:io';
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

  /// Builds the preview widget for the selected file
  Widget _buildFilePreview(BuildContext context, NfcProvider provider) {
    if (provider.selectedFile == null) return const SizedBox.shrink();

    final file = provider.selectedFile!;
    final fileName = provider.selectedFileName ?? 'Unknown File';
    final extension = fileName.split('.').last.toLowerCase();

    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (ctx, _, __) => _buildGenericFileIcon(fileName),
        ),
      );
    } else {
      return _buildGenericFileIcon(fileName);
    }
  }

  Widget _buildGenericFileIcon(String fileName) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Broadcast Content',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                        const SizedBox(height: 16),

                        // File / Image Preview
                        if (provider.selectedFile != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildFilePreview(context, provider),
                          ),

                        // Text / URL Display
                        if (provider.isBroadcasting)
                          Text(
                            provider.broadcastText,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          )
                        else
                          Column(
                            children: [
                              TextField(
                                controller: _textController,
                                decoration: InputDecoration(
                                  hintText: 'Enter text or URL',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: provider.selectedFile != null
                                      ? IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            provider.setBroadcastText('');
                                            _textController.clear();
                                          },
                                        )
                                      : null,
                                ),
                                textAlign: TextAlign.center,
                                onChanged: (value) {
                                  provider.setBroadcastText(value);
                                },
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await provider.pickFile();
                                  // Update controller with new URL
                                  _textController.text = provider.broadcastText;
                                },
                                icon: const Icon(Icons.attach_file),
                                label: const Text('Pick File'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Broadcast toggle button
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
                        // Hide keyboard
                        FocusScope.of(context).unfocus();
                        // Ensure provider has the latest text
                        provider.setBroadcastText(_textController.text);
                      }
                      provider.toggleBroadcast();
                    },
                  ),
                ),
                SizedBox(height: 16),

                // Active broadcast indicator
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
