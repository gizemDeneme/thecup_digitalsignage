import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/content_item_model.dart';
import '../../data/repositories/content_repository.dart';

final contentRepositoryProvider =
    Provider<ContentRepository>((ref) => getIt<ContentRepository>());

final contentByTypeProvider =
    StreamProvider.family<List<ContentItemModel>, ContentType>((ref, type) {
  return ref.watch(contentRepositoryProvider).watchByType(type);
});

final allContentProvider = FutureProvider<List<ContentItemModel>>((ref) {
  return ref.read(contentRepositoryProvider).getAll();
});

// Upload progress state
class UploadState {
  final bool isUploading;
  final double progress;
  final String? error;

  const UploadState({
    this.isUploading = false,
    this.progress = 0,
    this.error,
  });
}

class UploadNotifier extends StateNotifier<UploadState> {
  final ContentRepository _repo;

  UploadNotifier(this._repo) : super(const UploadState());

  Future<void> uploadVideo(File file, String title) async {
    state = const UploadState(isUploading: true, progress: 0);
    try {
      await _repo.uploadVideo(
        file: file,
        title: title,
        onProgress: (p) => state = UploadState(isUploading: true, progress: p),
      );
      state = const UploadState(progress: 1);
    } catch (e) {
      state = UploadState(error: e.toString());
    }
  }

  Future<void> uploadImage(File file, String title) async {
    state = const UploadState(isUploading: true, progress: 0);
    try {
      await _repo.uploadImage(
        file: file,
        title: title,
        onProgress: (p) => state = UploadState(isUploading: true, progress: p),
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
      state = const UploadState(progress: 1);
    } catch (e) {
      state = UploadState(error: e.toString());
    }
  }

  Future<void> savePriceList(PriceListModel list) async {
    state = const UploadState(isUploading: true, progress: 0.5);
    try {
      await _repo.savePriceList(list);
      state = const UploadState(progress: 1);
    } catch (e) {
      state = UploadState(error: e.toString());
    }
  }

  Future<void> delete(ContentItemModel item) async {
    await _repo.delete(item);
  }

  void reset() => state = const UploadState();
}

final uploadNotifierProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref.watch(contentRepositoryProvider));
});
