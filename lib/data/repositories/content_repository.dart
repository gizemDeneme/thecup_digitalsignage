import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
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

  Future<ContentItemModel?> getById(String id) => _firestore.getContent(id);

  /// Resizes image to max 1920px wide and compresses to JPEG 85%.
  Uint8List _compressImage(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      img.Image processed = decoded;
      if (decoded.width > 1920) {
        processed = img.copyResize(
          decoded,
          width: 1920,
          interpolation: img.Interpolation.linear,
        );
      }
      return Uint8List.fromList(img.encodeJpg(processed, quality: 85));
    } catch (_) {
      return bytes;
    }
  }

  Future<VideoItemModel> uploadVideo({
    required Uint8List bytes,
    required String fileName,
    required String title,
    required int fileSizeBytes,
    void Function(double progress)? onProgress,
  }) async {
    final id = _uuid.v4();

    final result = await _storage.uploadData(
      bytes: bytes,
      path: 'videos/$id',
      resourceType: 'video',
      onProgress: onProgress,
    );

    final item = VideoItemModel(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      storageUrl: result.publicId,
      downloadUrl: result.downloadUrl,
      fileSizeBytes: result.sizeBytes,
      durationSeconds: 0,
    );
    await _firestore.saveContent(item);
    return item;
  }

  Future<ImageItemModel> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String title,
    required int fileSizeBytes,
    void Function(double progress)? onProgress,
  }) async {
    final id = _uuid.v4();

    // Compress before upload (max 1920px wide, JPEG 85%)
    final compressed = _compressImage(bytes);

    final result = await _storage.uploadData(
      bytes: compressed,
      path: 'images/$id',
      resourceType: 'image',
      onProgress: onProgress,
    );

    final item = ImageItemModel(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      storageUrl: result.publicId,
      downloadUrl: result.downloadUrl,
      fileSizeBytes: result.sizeBytes,
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
    // storageUrl is Cloudinary publicId — no-op delete on client side
    if (item is VideoItemModel) {
      await _storage.deleteFile(item.storageUrl);
    } else if (item is ImageItemModel) {
      await _storage.deleteFile(item.storageUrl);
    }
  }
}
