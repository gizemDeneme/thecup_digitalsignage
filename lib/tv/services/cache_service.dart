import 'dart:io';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/playlist_model.dart';

class CacheService {
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(AppConstants.hivePlaylistBox);
  }

  /// Her TV'ye özgü, kalıcı kimlik. İlk çalıştırmada UUID üretilir, sonraki
  /// açılışlarda aynı değer döndürülür.
  String getOrCreateDeviceId() {
    const key = 'device_id';
    final existing = _box.get(key);
    if (existing != null) return existing as String;
    final id = const Uuid().v4();
    _box.put(key, id);
    return id;
  }

  Future<void> savePlaylist(PlaylistModel playlist) async {
    await _box.put(AppConstants.hiveActiveKey, jsonEncode(playlist.toMap()));
  }

  PlaylistModel? loadPlaylist() {
    final raw = _box.get(AppConstants.hiveActiveKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      return PlaylistModel.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<File?> getCachedVideo(String contentId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/${AppConstants.videoCacheDir}/$contentId.mp4');
    if (await file.exists()) return file;
    return null;
  }

  Future<void> downloadVideo(String contentId, String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir =
        Directory('${dir.path}/${AppConstants.videoCacheDir}');
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

    final file = File('${cacheDir.path}/$contentId.mp4');
    if (await file.exists()) return;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {
      // Download failed silently — will use network URL as fallback
    }
  }
}
