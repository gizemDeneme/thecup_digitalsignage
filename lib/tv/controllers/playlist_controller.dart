import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/content_item_model.dart';
import '../../data/services/firestore_service.dart';
import '../services/cache_service.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final cacheServiceProvider = Provider<CacheService>((ref) => getIt<CacheService>());

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => getIt<FirestoreService>());

final playlistStreamProvider = StreamProvider<PlaylistModel?>((ref) {
  return ref.watch(firestoreServiceProvider).watchActivePlaylist();
});

// ─── State ───────────────────────────────────────────────────────────────────

class PlaylistState {
  final PlaylistModel? playlist;
  final int currentIndex;
  final bool isOffline;

  const PlaylistState({
    this.playlist,
    this.currentIndex = 0,
    this.isOffline = false,
  });

  PlaylistItem? get currentItem {
    final p = playlist;
    if (p == null || p.items.isEmpty) return null;
    return p.items[currentIndex];
  }

  PlaylistState copyWith({
    PlaylistModel? playlist,
    int? currentIndex,
    bool? isOffline,
  }) {
    return PlaylistState(
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class PlaylistController extends StateNotifier<PlaylistState> {
  final CacheService _cache;
  Timer? _timer;

  PlaylistController(this._cache) : super(const PlaylistState());

  void onPlaylistUpdate(PlaylistModel? newPlaylist) {
    if (newPlaylist == null) return;
    _cache.savePlaylist(newPlaylist);
    state = state.copyWith(playlist: newPlaylist, currentIndex: 0, isOffline: false);
    _scheduleNextIfNeeded();

    // Video pre-caching is handled at widget level where the download URL is available
  }

  void loadFromCache() {
    final cached = _cache.loadPlaylist();
    if (cached != null) {
      state = state.copyWith(playlist: cached, currentIndex: 0, isOffline: true);
      _scheduleNextIfNeeded();
    }
  }

  void onVideoCompleted() {
    _goToNext();
  }

  void _scheduleNextIfNeeded() {
    final item = state.currentItem;
    if (item == null) return;
    if (item.type == ContentType.video) {
      // Video completion handled by VideoPlayerWidget callback
      _timer?.cancel();
    } else {
      _timer?.cancel();
      _timer = Timer(Duration(seconds: item.durationSeconds), _goToNext);
    }
  }

  void _goToNext() {
    final playlist = state.playlist;
    if (playlist == null || playlist.items.isEmpty) return;
    final nextIndex = (state.currentIndex + 1) % playlist.items.length;
    state = state.copyWith(currentIndex: nextIndex);
    _scheduleNextIfNeeded();
  }

  void setOffline(bool offline) {
    state = state.copyWith(isOffline: offline);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final playlistControllerProvider =
    StateNotifierProvider<PlaylistController, PlaylistState>((ref) {
  return PlaylistController(ref.watch(cacheServiceProvider));
});
