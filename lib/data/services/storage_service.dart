import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UploadTask uploadData({
    required Uint8List bytes,
    required String path,
    String? contentType,
  }) {
    final ref = _storage.ref(path);
    final metadata =
        contentType != null ? SettableMetadata(contentType: contentType) : null;
    return metadata != null ? ref.putData(bytes, metadata) : ref.putData(bytes);
  }

  Future<String> getDownloadUrl(String path) async {
    return _storage.ref(path).getDownloadURL();
  }

  Future<void> deleteFile(String storageUrl) async {
    try {
      final ref = _storage.refFromURL(storageUrl);
      await ref.delete();
    } catch (_) {
      // File may already be deleted
    }
  }
}
