import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/content_item_model.dart';
import '../../data/models/playlist_model.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../core/constants/app_constants.dart';

final playlistRepositoryProvider =
    Provider<PlaylistRepository>((ref) => getIt<PlaylistRepository>());

final activePlaylistStreamProvider = StreamProvider<PlaylistModel?>((ref) {
  return ref.watch(playlistRepositoryProvider).watchActive();
});

class PlaylistEditorNotifier extends StateNotifier<List<PlaylistItem>> {
  PlaylistEditorNotifier() : super([]);

  void addItem(ContentItemModel content) {
    final duration = switch (content.type) {
      ContentType.video => AppConstants.defaultImageDurationSeconds,
      ContentType.image => AppConstants.defaultImageDurationSeconds,
      ContentType.menu => AppConstants.defaultMenuDurationSeconds,
      ContentType.priceList => AppConstants.defaultPriceListDurationSeconds,
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

  void loadFromPlaylist(PlaylistModel playlist) {
    state = playlist.items;
  }

  void clear() => state = [];

  int get totalDurationSeconds =>
      state.fold(0, (sum, item) => sum + item.durationSeconds);
}

final playlistEditorProvider =
    StateNotifierProvider<PlaylistEditorNotifier, List<PlaylistItem>>(
        (ref) => PlaylistEditorNotifier());

final publishProvider = FutureProvider.autoDispose<void>((ref) async {
  final items = ref.read(playlistEditorProvider);
  await ref.read(playlistRepositoryProvider).publish(items);
});
