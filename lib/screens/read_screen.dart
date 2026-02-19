/// [read_screen.dart] — UI for reading NFC tags.
/// Part of the nfc_bridge project.
/// Platform: iOS and Android

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../providers/nfc_provider.dart';

import '../models/nfc_data.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  bool _isDownloading = false;

  /// Downloads a file from the given URL and attempts to open it.
  /// Used for handling file content types read from NFC tags.
  Future<void> _downloadAndOpenFile(String url, BuildContext context) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // 1. Download the file from the local server or internet
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // 2. Get local path in the app's documents directory
        final dir = await getApplicationDocumentsDirectory();

        // Extract filename from URL or use default
        String filename = url.split('/').last;
        if (filename.isEmpty || !filename.contains('.')) {
          filename = 'downloaded_file';
        }

        // ensure unique name if needed? For now overwrite is fine for testing.
        final file = File('${dir.path}/$filename');

        // 3. Save file locally
        await file.writeAsBytes(response.bodyBytes);

        // 4. Open file using open_file package
        final result = await OpenFile.open(file.path);

        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open file: ${result.message}')),
            );
          }
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Widget _buildContentDisplay(BuildContext context, NfcData data) {
    if (data.type == NfcDataType.mime) {
      // Check if it's an image based on mimeType
      if (data.mimeType != null && data.mimeType!.startsWith('image/')) {
        // Should we try to show image from URL if content is URL?
        // Or is content base64?
        // The current implementation of MimeRecord in service returns:
        // content = String from body (likely URL or base64?)
        // Wait, the previous logic assumed content was a URL.
        // If it's a real NFC tag with a file, it might just be the file data inline?
        // Or a URI record pointing to a file?

        // If the mime record is a URL (common for "smart posters"), treat as URL.
        // But here we likely have raw data if it's a true MimeRecord.
        // Let's assume for now if it looks like a URL, we show it as image/file download.

        if (data.content.startsWith('http')) {
          return Column(
            children: [
              Text('Image Detected',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  data.content,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                            'Could not load image. Server might be unreachable.',
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _downloadAndOpenFile(data.content, context),
                icon: const Icon(Icons.download),
                label: const Text('Download Image'),
              ),
            ],
          );
        }
      }

      // Generic File or non-image MIME
      final fileName = data.content.startsWith('http')
          ? data.content.split('/').last
          : 'Data';
      return Column(
        children: [
          const Icon(Icons.insert_drive_file, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text('File / Data Detected',
              style: Theme.of(context).textTheme.titleMedium),
          if (data.mimeType != null)
            Text(data.mimeType!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          if (data.content.startsWith('http'))
            ElevatedButton.icon(
              onPressed: () => _downloadAndOpenFile(data.content, context),
              icon: const Icon(Icons.download),
              label: const Text('Download & Open'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
            )
          else
            Text("Raw Data: ${data.content}", textAlign: TextAlign.center),
        ],
      );
    } // End MIME

    // Display Text or URI
    final isUri = data.type == NfcDataType.uri;
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
        if (isUri || data.content.startsWith('http')) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _downloadAndOpenFile(
                data.content, context), // Or launch URL properly
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open Link'),
          ),
        ]
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
                  if (!provider.isReading && !_isDownloading)
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
                    )
                  else if (_isDownloading)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Downloading content...'),
                      ],
                    ),

                  // Content Display
                  if (lastRead != null &&
                      !provider.isReading &&
                      !_isDownloading)
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
