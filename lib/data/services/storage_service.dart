import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UploadTask uploadFile({
    required File file,
    required String path,
  }) {
    final ref = _storage.ref(path);
    return ref.putFile(file);
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
