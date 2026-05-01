import '../models/content_item_model.dart';
import '../models/playlist_model.dart';
import '../models/screen_model.dart';
import '../services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class ScreenRepository {
  final FirestoreService _firestore;
  final _uuid = const Uuid();

  ScreenRepository(this._firestore);

  Stream<List<ScreenModel>> watchAll() => _firestore.watchAllScreens();

  Future<void> register(String deviceId) =>
      _firestore.registerScreen(deviceId);

  Future<void> publishToScreen(
      String deviceId, List<PlaylistItem> items) async {
    final playlist = PlaylistModel(
      id: _uuid.v4(),
      publishedAt: DateTime.now(),
      items: items,
    );
    await _firestore.publishToScreen(deviceId, playlist);
  }

  Future<void> updateName(String deviceId, String name) =>
      _firestore.updateScreenName(deviceId, name);
}
