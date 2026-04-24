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
  Timer? _contentTimer;
  Timer? _scheduleCheckTimer;

  PlaylistController(this._cache) : super(const PlaylistState()) {
    // Check every minute whether current item's time window has expired
    _scheduleCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSchedule(),
    );
  }

  void onPlaylistUpdate(PlaylistModel? newPlaylist) {
    if (newPlaylist == null) return;
    _cache.savePlaylist(newPlaylist);
    final startIndex = _firstActiveIndex(newPlaylist.items);
    state = state.copyWith(
      playlist: newPlaylist,
      currentIndex: startIndex,
      isOffline: false,
    );
    _scheduleNextIfNeeded();
  }

  void loadFromCache() {
    final cached = _cache.loadPlaylist();
    if (cached != null) {
      final startIndex = _firstActiveIndex(cached.items);
      state = state.copyWith(
        playlist: cached,
        currentIndex: startIndex,
        isOffline: true,
      );
      _scheduleNextIfNeeded();
    }
  }

  void onVideoCompleted() => _goToNext();

  // ── Schedule check ────────────────────────────────────────────────────────

  /// Called every minute to see if the current item is still in its window.
  void _checkSchedule() {
    final item = state.currentItem;
    if (item == null) return;
    if (!item.isActiveAt(DateTime.now())) {
      _goToNext();
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _scheduleNextIfNeeded() {
    final item = state.currentItem;
    if (item == null) return;
    if (item.type == ContentType.video) {
      _contentTimer?.cancel();
    } else {
      _contentTimer?.cancel();
      _contentTimer = Timer(
        Duration(seconds: item.durationSeconds),
        _goToNext,
      );
    }
  }

  void _goToNext() {
    final playlist = state.playlist;
    if (playlist == null || playlist.items.isEmpty) return;

    // Find next active item starting from current+1, wrapping around.
    final len = playlist.items.length;
    final now = DateTime.now();

    for (int i = 1; i <= len; i++) {
      final candidate = (state.currentIndex + i) % len;
      if (playlist.items[candidate].isActiveAt(now)) {
        state = state.copyWith(currentIndex: candidate);
        _scheduleNextIfNeeded();
        return;
      }
    }

    // No active items right now — retry in 30 seconds
    _contentTimer?.cancel();
    _contentTimer = Timer(const Duration(seconds: 30), _goToNext);
  }

  /// Returns the first active item index, or 0 as fallback.
  int _firstActiveIndex(List<PlaylistItem> items) {
    if (items.isEmpty) return 0;
    final now = DateTime.now();
    for (int i = 0; i < items.length; i++) {
      if (items[i].isActiveAt(now)) return i;
    }
    return 0; // fallback: start from beginning even if nothing is active yet
  }

  void setOffline(bool offline) => state = state.copyWith(isOffline: offline);

  @override
  void dispose() {
    _contentTimer?.cancel();
    _scheduleCheckTimer?.cancel();
    super.dispose();
  }
}

final playlistControllerProvider =
    StateNotifierProvider<PlaylistController, PlaylistState>((ref) {
  return PlaylistController(ref.watch(cacheServiceProvider));
});
