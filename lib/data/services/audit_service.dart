import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firestore_paths.dart';
import '../models/audit_log_model.dart';

/// Audit log servisi — admin aksiyonlarını kalıcı olarak Firestore'a yazar.
/// Yazılan loglar update/delete edilemez (Firestore rules ile kısıtlı).
class AuditService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _db.collection(FirestorePaths.auditLogs);

  /// Aksiyon kaydet. Kullanıcı login değilse hiçbir şey yapmaz.
  Future<void> log(
    AuditAction action, {
    String? targetType,
    String? targetId,
    String? targetName,
    Map<String, dynamic> metadata = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _logs.add({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'action': action.id,
        'targetType': targetType,
        'targetId': targetId,
        'targetName': targetName,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Audit log yazılamazsa ana işlemi bozmasın
      // ignore: avoid_print
      print('[AuditService] log failed: $e');
    }
  }

  /// Son N audit log'u stream'le (en yeni ilk).
  Stream<List<AuditLog>> watchRecent({int limit = 200}) {
    return _logs
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AuditLog.fromFirestore(d.id, d.data()))
            .toList());
  }
}
