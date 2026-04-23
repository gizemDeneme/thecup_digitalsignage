import '../models/playlist_model.dart';
import '../models/content_item_model.dart';
import '../services/firestore_service.dart';

class PlaylistRepository {
  final FirestoreService _firestore;

  PlaylistRepository(this._firestore);

  Stream<PlaylistModel?> watchActive() => _firestore.watchActivePlaylist();

  Future<PlaylistModel?> getActive() => _firestore.getActivePlaylist();

  Future<void> publish(List<PlaylistItem> items) async {
    final playlist = PlaylistModel(
      id: 'active',
      publishedAt: DateTime.now(),
      items: items,
    );
    await _firestore.publishPlaylist(playlist);
  }
}
