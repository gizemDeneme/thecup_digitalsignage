import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class _Cloudinary {
  static const String cloudName = 'dxdwxetle';
  static const String uploadPreset = 'thecup_uploads';
}

class StorageUploadResult {
  final String downloadUrl;
  final String publicId;
  final int sizeBytes;

  const StorageUploadResult({
    required this.downloadUrl,
    required this.publicId,
    required this.sizeBytes,
  });
}

class StorageService {
  /// Uploads bytes to Cloudinary.
  /// [resourceType] is 'image' or 'video'.
  Future<StorageUploadResult> uploadData({
    required Uint8List bytes,
    required String path,
    required String resourceType,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.05);

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${_Cloudinary.cloudName}/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _Cloudinary.uploadPreset
      ..fields['folder'] = path.contains('/') ? path.split('/').first : 'thecup'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: path.split('/').last,
      ));

    onProgress?.call(0.1);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        body['error']?['message'] ?? 'Yükleme başarısız (${response.statusCode})',
      );
    }

    onProgress?.call(1.0);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return StorageUploadResult(
      downloadUrl: json['secure_url'] as String,
      publicId: json['public_id'] as String,
      sizeBytes: (json['bytes'] as num).toInt(),
    );
  }

  /// Deletes a file from Cloudinary by publicId.
  /// Requires signed API call — skipped on client side.
  /// Files can be managed from Cloudinary dashboard if needed.
  Future<void> deleteFile(String publicId) async {
    // No-op: deletion is handled via Cloudinary dashboard
  }
}
