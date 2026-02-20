import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

class MediaClient {
  Future<Map<String, dynamic>> fetchInfo(String fileUrl) async {
    final baseUrl = fileUrl.replaceAll('/file', '');
    final infoUrl = '$baseUrl/info';

    final response = await http.get(Uri.parse(infoUrl));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch file info ${response.statusCode}');
    }
  }

  Future<String> downloadFile(
      String fileUrl, String filename, Function(double) onProgress) async {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(fileUrl));
    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception('Failed to download file ${response.statusCode}');
    }

    final contentLength = response.contentLength ?? 0;

    // Choose save directory
    final appDocDir = await getTemporaryDirectory();
    final savePath = '${appDocDir.path}/$filename';
    final file = File(savePath);

    var received = 0;
    final sink = file.openWrite();

    await for (var chunk in response.stream) {
      received += chunk.length;
      sink.add(chunk);
      if (contentLength > 0) {
        onProgress(received / contentLength);
      }
    }

    await sink.close();
    client.close();

    // Determine type and use gallery_saver if appropriate
    final lowerName = filename.toLowerCase();
    bool savedToGallery = false;

    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif')) {
      savedToGallery = await GallerySaver.saveImage(savePath) ?? false;
    } else if (lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.avi')) {
      savedToGallery = await GallerySaver.saveVideo(savePath) ?? false;
    }

    if (savedToGallery) {
      return 'Saved to Gallery';
    } else {
      // For audio or files not supported by gallery_saver, move to public downloads/documents
      final directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      if (Platform.isAndroid && !(await directory.exists())) {
        await directory.create(recursive: true);
      }

      final finalPath = '${directory.path}/$filename';
      await file.copy(finalPath);
      return 'Saved to: $finalPath';
    }
  }
}
