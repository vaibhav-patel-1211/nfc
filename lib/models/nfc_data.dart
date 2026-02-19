/// [nfc_data.dart]
/// Model to represent parsed NFC data strings and types.
enum NfcDataType {
  text,
  uri,
  mime,
  unknown,
}

class NfcData {
  final NfcDataType type;
  final String content; // Main display content (Text, URL, or Description)
  final String? mimeType; // Only for MIME type
  final List<int>? rawPayload; // Full payload for advanced use

  NfcData({
    required this.type,
    required this.content,
    this.mimeType,
    this.rawPayload,
  });

  @override
  String toString() {
    return 'NfcData(type: $type, content: $content, mimeType: $mimeType)';
  }
}
