import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/content_item_model.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/screen_model.dart';
import '../../data/models/screen_group_model.dart';
import '../../data/repositories/screen_repository.dart';

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

// ─── Playlist Editör ──────────────────────────────────────────────────────────

class PlaylistEditorNotifier extends StateNotifier<List<PlaylistItem>> {
  PlaylistEditorNotifier() : super([]);

  void addItem(ContentItemModel content) {
    final duration = switch (content) {
      VideoItemModel v => v.durationSeconds,
      _ => 5,
    };
    state = [
      ...state,
      PlaylistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: content.type,
        durationSeconds: duration,
        contentRef: 'content/${content.id}',
      ),
    ];
  }

  void removeAt(int index) {
    final list = [...state];
    list.removeAt(index);
    state = list;
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  void updateDuration(int index, int seconds) {
    final list = [...state];
    list[index] = list[index].copyWith(durationSeconds: seconds);
    state = list;
  }

  void updateTimeRange(int index, int? startMinutes, int? endMinutes) {
    final list = [...state];
    list[index] = list[index].copyWith(
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );
    state = list;
  }

  void clearTimeRange(int index) {
    final list = [...state];
    list[index] = list[index].copyWith(
      startMinutes: null,
      endMinutes: null,
    );
    state = list;
  }

  void loadFromPlaylist(PlaylistModel playlist) {
    state = playlist.items;
  }

  void clear() => state = [];

  int get totalDurationSeconds =>
      state.fold(0, (sum, item) => sum + item.durationSeconds);
}

/// Per-group playlist editörü — PlaylistEditorNotifier family ile
final groupEditorProvider = StateNotifierProvider.family<
    PlaylistEditorNotifier, List<PlaylistItem>, String>(
  (ref, groupId) => PlaylistEditorNotifier(),
);
