import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:network_info_plus/network_info_plus.dart';

class FileServerService {
  HttpServer? _server;

  /// Starts a local HTTP server to serve the selected file.
  /// Returns the URL that can be used to access the file.
  Future<String> startServer(File file) async {
    // Stop any existing server
    stopServer();

    // Create a handler that serves the specific file
    final handler = (shelf.Request request) {
      return shelf.Response.ok(
        file.openRead(),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': file.lengthSync().toString(),
          'Content-Disposition':
              'attachment; filename="${file.path.split('/').last}"',
        },
      );
    };

    // Bind to any available port on all interfaces (0.0.0.0)
    // allowing access from other devices on the LAN.
    _server = await io.serve(handler, '0.0.0.0', 0);

    // Get the device's IP address
    String ip = await _getLocalIpAddress();

    return 'http://$ip:${_server!.port}/${file.path.split('/').last}';
  }

  /// Stops the local HTTP server if it is running.
  void stopServer() {
    _server?.close(force: true);
    _server = null;
  }

  /// Returns the current server URL or empty string if not running.
  String getServerUrl() {
    if (_server == null) return '';
    return 'http://...'; // Simplified, strictly for state check
  }

  /// Helper to get the device's local IP address.
  /// Iterates through network interfaces to find a valid IPv4 address.
  Future<String> _getLocalIpAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: true,
    );

    try {
      // Try to find a non-loopback address (e.g., 192.168.x.x)
      // Prioritize Wi-Fi (wlan) or Ethernet (eth, en0) interfaces
      NetworkInterface interface = interfaces.firstWhere((element) =>
          element.name.contains('wlan') ||
          element.name.contains('eth') ||
          element.name.contains('en0'));
      return interface.addresses.first.address;
    } catch (e) {
      // Fallback: just take the first non-loopback address found
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    }
    return '127.0.0.1'; // Fallback to localhost
  }
}
