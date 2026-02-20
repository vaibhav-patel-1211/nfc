import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:network_info_plus/network_info_plus.dart';

class MediaServer {
  HttpServer? _server;
  File? _currentFile;
  String? _serverUrl;

  Future<String?> startServer(File file) async {
    _currentFile = file;

    // Get current local IP
    final info = NetworkInfo();
    final wifiIP = await info.getWifiIP();

    if (wifiIP == null) {
      throw Exception('Not connected to Wi-Fi. Please connect to a Wi-Fi network.');
    }

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_requestHandler);

    try {
      _server = await io.serve(handler, wifiIP, 8080);
      _serverUrl = 'http://$wifiIP:8080/file';
      return _serverUrl;
    } catch (e) {
      throw Exception('Failed to start server on $wifiIP:8080 - ${e.toString()}');
    }
  }

  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _currentFile = null;
      _serverUrl = null;
    }
  }

  Future<Response> _requestHandler(Request request) async {
    if (_currentFile == null || !await _currentFile!.exists()) {
      return Response.notFound('File not found');
    }

    if (request.url.path == 'info') {
      final stat = await _currentFile!.stat();
      final filename = _currentFile!.path.split('/').last;

      final info = {
        'filename': filename,
        'size': stat.size,
      };

      return Response.ok(
        jsonEncode(info),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (request.url.path == 'file') {
      final stat = await _currentFile!.stat();
      final stream = _currentFile!.openRead();

      return Response.ok(
        stream,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': stat.size.toString(),
          'Content-Disposition': 'attachment; filename="${_currentFile!.path.split('/').last}"',
        },
      );
    }

    return Response.notFound('Route not found');
  }
}
