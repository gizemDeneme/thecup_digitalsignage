import 'package:cloud_firestore/cloud_firestore.dart';

/// Tüm admin aksiyonları için audit log kaydı.
/// Firestore'da sadece create izinli (immutable).
class AuditLog {
  final String id;
  final String userId;
  final String userEmail;
  final AuditAction action;
  final String? targetType;   // 'content', 'playlist', 'user'
  final String? targetId;
  final String? targetName;   // human-readable (ör. "Yaz Menüsü")
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    this.targetType,
    this.targetId,
    this.targetName,
    this.metadata = const {},
    required this.timestamp,
  });

  factory AuditLog.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['timestamp'];
    return AuditLog(
      id: id,
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      action: AuditAction.parse(data['action'] as String?),
      targetType: data['targetType'] as String?,
      targetId: data['targetId'] as String?,
      targetName: data['targetName'] as String?,
      metadata:
          (data['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userEmail': userEmail,
        'action': action.id,
        'targetType': targetType,
        'targetId': targetId,
        'targetName': targetName,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      };
}

enum AuditAction {
  signIn('auth.sign_in', 'Giriş yaptı'),
  signOut('auth.sign_out', 'Çıkış yaptı'),

  contentUpload('content.upload', 'İçerik yükledi'),
  contentUpdate('content.update', 'İçerik düzenledi'),
  contentDelete('content.delete', 'İçerik sildi'),

  playlistPublish('playlist.publish', 'Playlist yayınladı'),

  userCreate('user.create', 'Kullanıcı ekledi'),
  userDisable('user.disable', 'Kullanıcı pasifleştirdi'),
  userEnable('user.enable', 'Kullanıcı aktifleştirdi'),

  unknown('unknown', 'Bilinmeyen');

  final String id;
  final String label;
  const AuditAction(this.id, this.label);

  static AuditAction parse(String? raw) {
    if (raw == null) return AuditAction.unknown;
    return AuditAction.values.firstWhere(
      (a) => a.id == raw,
      orElse: () => AuditAction.unknown,
    );
  }
}
