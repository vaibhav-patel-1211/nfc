/// [read_screen.dart] — UI for reading NFC tags.
/// Part of the nfc_bridge project.
/// Platform: iOS and Android

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nfc_provider.dart';
import '../models/nfc_data.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  Widget _buildContentDisplay(BuildContext context, NfcData data) {
    // Unwrap our custom MIME type to behave normally downstream
    var displayType = data.type;

    if (data.type == NfcDataType.mime &&
        data.mimeType?.toLowerCase().trim() == 'application/vnd.nfcbridge') {
      if (data.content.startsWith('http://') ||
          data.content.startsWith('https://')) {
        displayType = NfcDataType.uri;
      } else {
        displayType = NfcDataType.text;
      }
    }

    // Display Text or URI
    final isUri = displayType == NfcDataType.uri;
    final icon = isUri ? Icons.link : Icons.text_fields;
    final title = isUri ? 'URI Content' : 'Text Content';

    return Column(
      children: [
        Icon(icon, size: 48, color: Colors.black54),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            data.content,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: data.content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NfcProvider>(
      builder: (context, provider, child) {
        final lastRead = provider.lastRead;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Scan button
                  if (!provider.isReading)
                    SizedBox(
                      width: 220,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.nfc, size: 28),
                        label: const Text(
                          'Scan Tag',
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: provider.startRead,
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Loading states
                  if (provider.isReading)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Hold device near NFC tag...'),
                      ],
                    ),

                  // Content Display
                  if (lastRead != null && !provider.isReading)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green[600], size: 28),
                                const SizedBox(width: 8),
                                const Text(
                                  'Scan Successful',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            _buildContentDisplay(context, lastRead),
                          ],
                        ),
                      ),
                    ),

                  // Error state
                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  provider.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
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
