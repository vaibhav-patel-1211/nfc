import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:network_info_plus/network_info_plus.dart';

class FileServerService {
  HttpServer? _server;
  String? _serverUrl;

  /// Starts the server hosting the given [file].
  /// Returns the full URL to access the file.
  Future<String> startServer(File file) async {
    // If a server is already running, stop it first
    await stopServer();

    // Get the device's local IP address
    final info = NetworkInfo();
    var wifiIP = await info.getWifiIP();

    // Fallback if IP is null (e.g., hotspot or emulator)
    if (wifiIP == null) {
      // Try to find a valid non-loopback interface
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            wifiIP = addr.address;
            break;
          }
        }
        if (wifiIP != null) break;
      }
    }

    if (wifiIP == null) {
      throw Exception(
          'Could not determine device IP address. Ensure Wi-Fi is connected.');
    }

    // Create a handler that serves the specific file
    final handler = createStaticHandler(
      file.parent.path,
      defaultDocument: file.uri.pathSegments.last,
    );

    // Bind to the IP address on an ephemeral port (0)
    _server = await shelf_io.serve(handler, wifiIP, 0);

    // Construct the URL
    // We use the file name as the path
    final fileName = file.uri.pathSegments.last;
    _serverUrl = 'http://${_server!.address.host}:${_server!.port}/$fileName';

    print('File Server running at: $_serverUrl');
    return _serverUrl!;
  }

  /// Stops the server if it's running.
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _serverUrl = null;
      print('File Server stopped');
    }
  }

  /// Returns the current server URL or null if not running.
  String? getServerUrl() {
    return _serverUrl;
  }
}
