import '../models/content_item_model.dart';
import '../models/playlist_model.dart';
import '../models/screen_model.dart';
import '../models/screen_group_model.dart';
import '../services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class ScreenRepository {
  final FirestoreService _firestore;
  final _uuid = const Uuid();

  ScreenRepository(this._firestore);

  // ── Cihazlar ──────────────────────────────────────────────────────────────

  Stream<List<ScreenModel>> watchAllScreens() =>
      _firestore.watchAllScreens();

  Future<void> register(String deviceId) =>
      _firestore.registerScreen(deviceId);

  Future<void> assignToGroup(String deviceId, String? groupId) =>
      _firestore.assignScreenToGroup(deviceId, groupId);

  Future<void> updateName(String deviceId, String name) =>
      _firestore.updateScreenName(deviceId, name);

  Future<void> delete(String deviceId) =>
      _firestore.deleteScreen(deviceId);

  // ── Gruplar ───────────────────────────────────────────────────────────────

  Stream<List<ScreenGroupModel>> watchAllGroups() =>
      _firestore.watchAllGroups();

  Stream<PlaylistModel?> watchGroupPlaylist(String groupId) =>
      _firestore.watchGroupPlaylist(groupId);

  Stream<String?> watchDeviceGroup(String deviceId) =>
      _firestore.watchDeviceGroup(deviceId);

  Future<void> publishToGroup(
      String groupId, List<PlaylistItem> items) async {
    final playlist = PlaylistModel(
      id: _uuid.v4(),
      publishedAt: DateTime.now(),
      items: items,
    );
    await _firestore.publishToGroup(groupId, playlist);
  }

  Future<void> setGroupPaused(String groupId, bool paused) =>
      _firestore.setGroupPaused(groupId, paused);

  Stream<bool> watchGroupPaused(String groupId) =>
      _firestore.watchGroupPaused(groupId);

  Future<void> ensureDefaultGroups() =>
      _firestore.ensureDefaultGroups();
}
