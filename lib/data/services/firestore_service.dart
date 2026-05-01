import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../models/content_item_model.dart';
import '../models/playlist_model.dart';
import '../models/screen_group_model.dart';
import '../models/screen_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Content ───────────────────────────────────────────────────────────────

  Future<void> saveContent(ContentItemModel item) async {
    await _db.collection(FirestorePaths.content).doc(item.id).set(item.toMap());
  }

  Future<void> deleteContent(String id) async {
    await _db.collection(FirestorePaths.content).doc(id).delete();
  }

  Future<ContentItemModel?> getContent(String id) async {
    final doc = await _db.collection(FirestorePaths.content).doc(id).get();
    if (!doc.exists) return null;
    return ContentItemModel.fromFirestore(doc);
  }

  Stream<List<ContentItemModel>> watchContentByType(ContentType type) {
    return _db
        .collection(FirestorePaths.content)
        .where('type', isEqualTo: contentTypeToString(type))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ContentItemModel.fromFirestore(d)).toList());
  }

  Future<List<ContentItemModel>> getAllContent() async {
    final snap = await _db
        .collection(FirestorePaths.content)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ContentItemModel.fromFirestore(d)).toList();
  }

  // ─── Playlist ──────────────────────────────────────────────────────────────

  Future<void> publishPlaylist(PlaylistModel playlist) async {
    await _db
        .doc(FirestorePaths.activePlaylist)
        .set(playlist.toMap());
  }

  Stream<PlaylistModel?> watchActivePlaylist() {
    return _db.doc(FirestorePaths.activePlaylist).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return PlaylistModel.fromMap(snap.data()!);
    });
  }

  Future<PlaylistModel?> getActivePlaylist() async {
    final doc = await _db.doc(FirestorePaths.activePlaylist).get();
    if (!doc.exists || doc.data() == null) return null;
    return PlaylistModel.fromMap(doc.data()!);
  }

  // ─── Admin check ───────────────────────────────────────────────────────────

  Future<bool> isAdmin(String uid) async {
    final doc =
        await _db.collection(FirestorePaths.admins).doc(uid).get();
    return doc.exists;
  }

  // ─── Screens (cihaz kaydı ve grup ataması) ─────────────────────────────────

  Stream<List<ScreenModel>> watchAllScreens() {
    return _db
        .collection(FirestorePaths.screens)
        .orderBy('lastSeenAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ScreenModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// TV kendi grubunu öğrenmek için kendi dokümanını dinler.
  Stream<String?> watchDeviceGroup(String deviceId) {
    return _db
        .collection(FirestorePaths.screens)
        .doc(deviceId)
        .snapshots()
        .map((snap) => snap.data()?['groupId'] as String?);
  }

  Future<void> registerScreen(String deviceId) async {
    await _db.collection(FirestorePaths.screens).doc(deviceId).set(
      {'lastSeenAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> assignScreenToGroup(String deviceId, String? groupId) async {
    await _db.collection(FirestorePaths.screens).doc(deviceId).set(
      {'groupId': groupId},
      SetOptions(merge: true),
    );
  }

  Future<void> updateScreenName(String deviceId, String name) async {
    await _db
        .collection(FirestorePaths.screens)
        .doc(deviceId)
        .set({'name': name}, SetOptions(merge: true));
  }

  Future<void> deleteScreen(String deviceId) async {
    await _db.collection(FirestorePaths.screens).doc(deviceId).delete();
  }

  // ─── Screen Groups (Ekran 1 / Ekran 2) ─────────────────────────────────────

  static const List<Map<String, String>> defaultGroups = [
    {'id': 'ekran_1', 'name': 'Ekran 1'},
    {'id': 'ekran_2', 'name': 'Ekran 2'},
  ];

  Stream<List<ScreenGroupModel>> watchAllGroups() {
    return _db
        .collection(FirestorePaths.screenGroups)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ScreenGroupModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// TV'nin kendi grubunun playlist'ini dinler.
  Stream<PlaylistModel?> watchGroupPlaylist(String groupId) {
    return _db
        .collection(FirestorePaths.screenGroups)
        .doc(groupId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final raw = snap.data()!['playlist'];
      if (raw == null) return null;
      try {
        return PlaylistModel.fromMap(raw as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    });
  }

  Future<void> publishToGroup(String groupId, PlaylistModel playlist) async {
    await _db
        .collection(FirestorePaths.screenGroups)
        .doc(groupId)
        .set({'playlist': playlist.toMap()}, SetOptions(merge: true));
  }

  /// Grupları ilk kez oluşturur (Ekran 1, Ekran 2). Varsa dokunmaz.
  Future<void> ensureDefaultGroups() async {
    for (final g in defaultGroups) {
      final doc = await _db
          .collection(FirestorePaths.screenGroups)
          .doc(g['id']!)
          .get();
      if (!doc.exists) {
        await _db
            .collection(FirestorePaths.screenGroups)
            .doc(g['id']!)
            .set({'name': g['name']!});
      }
    }
  }
}
