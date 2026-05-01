import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/screen_model.dart';
import '../../data/models/content_item_model.dart';
import '../../data/repositories/screen_repository.dart';
import 'playlist_provider.dart';

final screenRepositoryProvider =
    Provider<ScreenRepository>((ref) => getIt<ScreenRepository>());

final allScreensProvider = StreamProvider<List<ScreenModel>>((ref) {
  return ref.watch(screenRepositoryProvider).watchAll();
});

/// Per-screen playlist editörü — her deviceId için ayrı state tutar.
/// PlaylistEditorNotifier'ı family ile yeniden kullanır.
final screenEditorProvider = StateNotifierProvider.family<
    PlaylistEditorNotifier, List<PlaylistItem>, String>(
  (ref, deviceId) => PlaylistEditorNotifier(),
);
