import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/screen_model.dart';
import '../../data/models/screen_group_model.dart';
import '../../data/models/content_item_model.dart';
import '../../data/repositories/screen_repository.dart';
import 'playlist_provider.dart';

final screenRepositoryProvider =
    Provider<ScreenRepository>((ref) => getIt<ScreenRepository>());

/// Tüm kayıtlı cihazlar (admin → Cihazlar bölümü)
final allScreensProvider = StreamProvider<List<ScreenModel>>((ref) {
  return ref.watch(screenRepositoryProvider).watchAllScreens();
});

/// Tüm gruplar (Ekran 1, Ekran 2)
final allGroupsProvider = StreamProvider<List<ScreenGroupModel>>((ref) {
  return ref.watch(screenRepositoryProvider).watchAllGroups();
});

/// Per-group playlist editörü — PlaylistEditorNotifier family ile
final groupEditorProvider = StateNotifierProvider.family<
    PlaylistEditorNotifier, List<PlaylistItem>, String>(
  (ref, groupId) => PlaylistEditorNotifier(),
);
