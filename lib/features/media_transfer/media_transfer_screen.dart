import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/nfc_provider.dart';
import 'media_server.dart';
import 'media_client.dart';

class MediaTransferScreen extends StatefulWidget {
  const MediaTransferScreen({super.key});

  @override
  State<MediaTransferScreen> createState() => _MediaTransferScreenState();
}

class _MediaTransferScreenState extends State<MediaTransferScreen> {
  final MediaServer _server = MediaServer();
  final MediaClient _client = MediaClient();

  bool _isSender = true; // true = Sender, false = Receiver

  // Sender state
  File? _selectedFile;
  String? _serverUrl;
  bool _isServerRunning = false;
  String? _errorMessage;

  // Receiver state
  String? _scannedUrl;
  Map<String, dynamic>? _fileInfo;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadResult;

  @override
  void dispose() {
    _server.stopServer();
    final provider = Provider.of<NfcProvider>(context, listen: false);
    if (provider.isBroadcasting) {
      provider.stopBroadcast();
    }
    super.dispose();
  }

  // --- SENDER LOGIC ---

  Future<void> _pickFileAndStart() async {
    setState(() {
      _errorMessage = null;
    });

    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });

      try {
        final url = await _server.startServer(_selectedFile!);
        setState(() {
          _isServerRunning = true;
          _serverUrl = url;
        });

        // Start broadcasting
        if (!mounted) return;
        final provider = Provider.of<NfcProvider>(context, listen: false);
        provider.setBroadcastText(_serverUrl!);
        await provider.startBroadcast();
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isServerRunning = false;
          _selectedFile = null;
        });
        _server.stopServer();
      }
    }
  }

  Future<void> _stopServer() async {
    await _server.stopServer();
    if (!mounted) return;
    final provider = Provider.of<NfcProvider>(context, listen: false);
    if (provider.isBroadcasting) {
      await provider.stopBroadcast();
    }
    setState(() {
      _isServerRunning = false;
      _serverUrl = null;
      _selectedFile = null;
    });
  }

  // --- RECEIVER LOGIC ---

  Future<void> _scanNfc() async {
    setState(() {
      _errorMessage = null;
      _scannedUrl = null;
      _fileInfo = null;
      _downloadResult = null;
      _downloadProgress = 0.0;
    });

    final provider = Provider.of<NfcProvider>(context, listen: false);
    await provider.startRead();

    final data = provider.lastRead;
    if (data == null) {
      if (provider.errorMessage != null) {
        setState(() {
          _errorMessage = provider.errorMessage;
        });
      }
      return;
    }

    // Check if it's a media URL
    String content = data.content;

    // Pattern: http://<ip>:8080/file
    final ipRegex = RegExp(r'^http:\/\/(?:\d{1,3}\.){3}\d{1,3}:8080\/file$');
    if (ipRegex.hasMatch(content)) {
      setState(() {
        _scannedUrl = content;
      });
      _fetchFileInfo(content);
    } else {
      // Not a media URL, pop to let ReadScreen handle it
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _fetchFileInfo(String url) async {
    try {
      final info = await _client.fetchInfo(url);
      setState(() {
        _fileInfo = info;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to fetch file info from sender. Make sure they are on the same Wi-Fi.';
      });
    }
  }

  Future<void> _downloadFile() async {
    if (_scannedUrl == null || _fileInfo == null) return;

    setState(() {
      _isDownloading = true;
      _downloadResult = null;
      _errorMessage = null;
    });

    try {
      final String result = await _client.downloadFile(
        _scannedUrl!,
        _fileInfo!['filename'],
        (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      setState(() {
        _downloadResult = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Download failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  // --- UI BUILDING ---

  Widget _buildSenderUI() {
    if (_isServerRunning && _serverUrl != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_tethering, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Broadcasting via NFC',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Tap phones together to share.'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                      'File: ${_selectedFile?.path.split('/').last ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  Text('URL: $_serverUrl',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Stop Sharing'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: _stopServer,
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.upload_file, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Select a file to share over local Wi-Fi.'),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text('Pick Media File'),
          onPressed: _pickFileAndStart,
        ),
      ],
    );
  }

  Widget _buildReceiverUI() {
    final provider = context.watch<NfcProvider>();

    if (provider.isReading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Hold device near NFC tag...'),
        ],
      );
    }

    if (_scannedUrl != null && _fileInfo != null) {
      // Show file info and prompt
      final sizeMb = (_fileInfo!['size'] as int) / (1024 * 1024);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.download, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('Incoming File',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Filename: ${_fileInfo!['filename']}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Size: ${sizeMb.toStringAsFixed(2)} MB'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isDownloading) ...[
            LinearProgressIndicator(value: _downloadProgress),
            const SizedBox(height: 8),
            Text('${(_downloadProgress * 100).toStringAsFixed(1)}%'),
          ] else if (_downloadResult != null) ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            Text(_downloadResult!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Scan Another'),
              onPressed: () {
                setState(() {
                  _scannedUrl = null;
                  _fileInfo = null;
                  _downloadResult = null;
                });
              },
            )
          ] else ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download File'),
              onPressed: _downloadFile,
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _scannedUrl = null;
                  _fileInfo = null;
                });
              },
              child: const Text('Cancel'),
            ),
          ]
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.nfc, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Ready to receive files via NFC.'),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.sensors),
          label: const Text('Scan via NFC'),
          onPressed: _scanNfc,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Transfer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mode Selector
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Share a File'),
                  icon: Icon(Icons.upload),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Receive a File'),
                  icon: Icon(Icons.download),
                ),
              ],
              selected: {_isSender},
              onSelectionChanged: (Set<bool> newSelection) {
                if (newSelection.isNotEmpty) {
                  // Stop server/broadcast if switching away from Sender
                  if (_isSender && !newSelection.first) {
                    _stopServer();
                  }

                  // Reset states
                  setState(() {
                    _isSender = newSelection.first;
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // Error Display
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: _isSender ? _buildSenderUI() : _buildReceiverUI(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
