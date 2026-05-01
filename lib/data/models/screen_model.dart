import 'package:cloud_firestore/cloud_firestore.dart';
import 'playlist_model.dart';

class ScreenModel {
  final String deviceId;
  final String name;
  final DateTime lastSeenAt;
  final PlaylistModel? playlist;

  const ScreenModel({
    required this.deviceId,
    required this.name,
    required this.lastSeenAt,
    this.playlist,
  });

  factory ScreenModel.fromFirestore(String id, Map<String, dynamic> data) {
    PlaylistModel? playlist;
    final raw = data['playlist'];
    if (raw != null) {
      try {
        playlist = PlaylistModel.fromMap(raw as Map<String, dynamic>);
      } catch (_) {}
    }
    return ScreenModel(
      deviceId: id,
      name: data['name'] as String? ?? id,
      lastSeenAt: (data['lastSeenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      playlist: playlist,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'lastSeenAt': Timestamp.fromDate(lastSeenAt),
        if (playlist != null) 'playlist': playlist!.toMap(),
      };

  ScreenModel copyWith({String? name, DateTime? lastSeenAt, PlaylistModel? playlist}) {
    return ScreenModel(
      deviceId: deviceId,
      name: name ?? this.name,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      playlist: playlist ?? this.playlist,
    );
  }

  /// Son görülme zamanını insan-okunabilir formata çevirir.
  String get lastSeenLabel {
    final diff = DateTime.now().difference(lastSeenAt);
    if (diff.inSeconds < 60) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }

  /// 2 dakikadan az önce görülmüşse online sayılır.
  bool get isOnline => DateTime.now().difference(lastSeenAt).inMinutes < 2;
}
