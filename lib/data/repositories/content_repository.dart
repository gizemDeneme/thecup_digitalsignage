import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/content_item_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ContentRepository {
  final FirestoreService _firestore;
  final StorageService _storage;
  final _uuid = const Uuid();

  ContentRepository(this._firestore, this._storage);

  Stream<List<ContentItemModel>> watchByType(ContentType type) =>
      _firestore.watchContentByType(type);

  Future<List<ContentItemModel>> getAll() => _firestore.getAllContent();

  Future<VideoItemModel> uploadVideo({
    required File file,
    required String title,
    void Function(double progress)? onProgress,
  }) async {
    final id = _uuid.v4();
    final path = 'videos/$id.mp4';
    final task = _storage.uploadFile(file: file, path: path);

    task.snapshotEvents.listen((snapshot) {
      if (onProgress != null && snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    await task;
    final downloadUrl = await _storage.getDownloadUrl(path);
    final stat = await file.stat();

    final item = VideoItemModel(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      storageUrl: 'gs://${FirebaseStorage.instance.bucket}/$path',
      downloadUrl: downloadUrl,
      fileSizeBytes: stat.size,
      durationSeconds: 0,
    );
    await _firestore.saveContent(item);
    return item;
  }

  Future<ImageItemModel> uploadImage({
    required File file,
    required String title,
    void Function(double progress)? onProgress,
  }) async {
    final id = _uuid.v4();
    final ext = file.path.split('.').last.toLowerCase();
    final path = 'images/$id.$ext';
    final task = _storage.uploadFile(file: file, path: path);

    task.snapshotEvents.listen((snapshot) {
      if (onProgress != null && snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    await task;
    final downloadUrl = await _storage.getDownloadUrl(path);
    final stat = await file.stat();

    final item = ImageItemModel(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      storageUrl: 'gs://${FirebaseStorage.instance.bucket}/$path',
      downloadUrl: downloadUrl,
      fileSizeBytes: stat.size,
    );
    await _firestore.saveContent(item);
    return item;
  }

  Future<void> saveMenu(MenuItemModel menu) async {
    await _firestore.saveContent(menu);
  }

  Future<void> savePriceList(PriceListModel list) async {
    await _firestore.saveContent(list);
  }

  Future<void> delete(ContentItemModel item) async {
    await _firestore.deleteContent(item.id);
    if (item is VideoItemModel) {
      await _storage.deleteFile(item.storageUrl);
    } else if (item is ImageItemModel) {
      await _storage.deleteFile(item.storageUrl);
    }
  }
}
