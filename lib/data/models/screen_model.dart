import 'package:cloud_firestore/cloud_firestore.dart';

class ScreenModel {
  final String deviceId;
  final String name;
  final DateTime lastSeenAt;
  final String? groupId;   // "ekran_1" | "ekran_2" | null (atanmamış)

  const ScreenModel({
    required this.deviceId,
    required this.name,
    required this.lastSeenAt,
    this.groupId,
  });

  factory ScreenModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ScreenModel(
      deviceId: id,
      name: data['name'] as String? ?? id,
      lastSeenAt: (data['lastSeenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      groupId: data['groupId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'lastSeenAt': Timestamp.fromDate(lastSeenAt),
        if (groupId != null) 'groupId': groupId,
      };

  ScreenModel copyWith({String? name, DateTime? lastSeenAt, String? groupId}) {
    return ScreenModel(
      deviceId: deviceId,
      name: name ?? this.name,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      groupId: groupId ?? this.groupId,
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
