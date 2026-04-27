import 'dart:typed_data';
import 'package:dio/dio.dart';

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
  final _dio = Dio();

  /// Uploads bytes to Cloudinary.
  /// [resourceType] is 'image' or 'video'.
  Future<StorageUploadResult> uploadData({
    required Uint8List bytes,
    required String path,
    required String resourceType,
    void Function(double progress)? onProgress,
  }) async {
    final uri =
        'https://api.cloudinary.com/v1_1/${_Cloudinary.cloudName}/$resourceType/upload';

    final formData = FormData.fromMap({
      'upload_preset': _Cloudinary.uploadPreset,
      'folder': path.contains('/') ? path.split('/').first : 'thecup',
      'file': MultipartFile.fromBytes(
        bytes,
        filename: path.split('/').last,
      ),
    });

    final response = await _dio.post(
      uri,
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0 && onProgress != null) {
          onProgress(sent / total);
        }
      },
      options: Options(
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      ),
    );

    if (response.statusCode != 200) {
      final msg = response.data?['error']?['message'] ?? 'Yükleme başarısız';
      throw Exception(msg);
    }

    final data = response.data as Map<String, dynamic>;
    String downloadUrl = data['secure_url'] as String;

    // Video URL'lerine .mp4 uzantısı ekle — Android ExoPlayer format tanıması için
    if (resourceType == 'video' && !downloadUrl.contains('.mp4')) {
      downloadUrl = '$downloadUrl.mp4';
    }

    return StorageUploadResult(
      downloadUrl: downloadUrl,
      publicId: data['public_id'] as String,
      sizeBytes: (data['bytes'] as num).toInt(),
    );
  }

  Future<void> deleteFile(String publicId) async {
    // Deletion managed via Cloudinary dashboard
  }
}
