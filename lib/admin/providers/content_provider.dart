import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/models/content_item_model.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/services/audit_service.dart';

final contentRepositoryProvider =
    Provider<ContentRepository>((ref) => getIt<ContentRepository>());

final contentByTypeProvider =
    StreamProvider.family<List<ContentItemModel>, ContentType>((ref, type) {
  return ref.watch(contentRepositoryProvider).watchByType(type);
});

final allContentProvider = FutureProvider<List<ContentItemModel>>((ref) {
  return ref.read(contentRepositoryProvider).getAll();
});

/// contentId → title map, playlist editörünün içerik adlarını göstermesi için
final contentTitleMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final list = await ref.read(contentRepositoryProvider).getAll();
  return {for (final c in list) c.id: c.title};
});

// Upload progress state
class UploadState {
  final bool isUploading;
  final bool isCompressing;
  final double progress;
  final String? error;

  const UploadState({
    this.isUploading = false,
    this.isCompressing = false,
    this.progress = 0,
    this.error,
  });
}

class UploadNotifier extends StateNotifier<UploadState> {
  final ContentRepository _repo;
  final AuditService _audit;

  UploadNotifier(this._repo, this._audit) : super(const UploadState());

  Future<void> uploadVideo({
    required Uint8List bytes,
    required String fileName,
    required String title,
    required int fileSizeBytes,
  }) async {
    state = const UploadState(isUploading: true, progress: 0);
    try {
      final result = await _repo.uploadVideo(
        bytes: bytes,
        fileName: fileName,
        title: title,
        fileSizeBytes: fileSizeBytes,
        onProgress: (p) => state = UploadState(isUploading: true, progress: p),
      );
      await _audit.log(
        AuditAction.contentUpload,
        targetType: 'content.video',
        targetId: result.id,
        targetName: title,
        metadata: {'fileName': fileName, 'sizeBytes': fileSizeBytes},
      );
      state = const UploadState(progress: 1);
    } catch (e) {
      state = UploadState(error: e.toString());
    }
  }

  Future<void> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String title,
    required int fileSizeBytes,
  }) async {
    state = const UploadState(isUploading: true, isCompressing: true, progress: 0);
    try {
      final result = await _repo.uploadImage(
        bytes: bytes,
        fileName: fileName,
        title: title,
        fileSizeBytes: fileSizeBytes,
        onProgress: (p) => state = UploadState(isUploading: true, isCompressing: false, progress: p),
      );
      await _audit.log(
        AuditAction.contentUpload,
        targetType: 'content.image',
        targetId: result.id,
        targetName: title,
        metadata: {'fileName': fileName, 'sizeBytes': fileSizeBytes},
      );
      state = const UploadState(progress: 1);
    } catch (e) {
      state = UploadState(error: e.toString());
    }
  }

  Future<void> saveMenu(MenuItemModel menu) async {
    state = const UploadState(isUploading: true, progress: 0.5);
    try {
      await _repo.saveMenu(menu);
      await _audit.log(
        AuditAction.contentUpload,
        targetType: 'content.menu',
        targetId: menu.id,
        targetName: menu.title,
      );
      state = const UploadState(progress: 1);
    } catch (e) {
      state = UploadState(error: e.toString());
    }
  }

  Future<void> savePriceList(PriceListModel list) async {
    state = const UploadState(isUploading: true, progress: 0.5);
    try {
      await _repo.savePriceList(list);
      await _audit.log(
        AuditAction.contentUpload,
        targetType: 'content.price_list',
        targetId: list.id,
        targetName: list.title,
      );
      state = const UploadState(progress: 1);
    } catch (e) {
      state = UploadState(error: e.toString());
    }
  }

  Future<void> delete(ContentItemModel item) async {
    await _repo.delete(item);
    await _audit.log(
      AuditAction.contentDelete,
      targetType: 'content.${item.type.name}',
      targetId: item.id,
      targetName: item.title,
    );
  }

  void reset() => state = const UploadState();
}

final auditServiceForContentProvider =
    Provider<AuditService>((ref) => getIt<AuditService>());

final uploadNotifierProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(
    ref.watch(contentRepositoryProvider),
    ref.watch(auditServiceForContentProvider),
  );
});
