import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/constants/firestore_paths.dart';
import '../../firebase_options.dart';
import '../models/admin_user_model.dart';

/// Admin kullanıcı yönetimi.
/// Yeni kullanıcı oluşturmak için **secondary** Firebase app instance kullanır
/// (mevcut admin'in oturumunu bozmamak için).
class AdminUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _admins =>
      _db.collection(FirestorePaths.admins);

  /// Tüm admin kullanıcıları listele.
  Stream<List<AdminUser>> watchAll() {
    return _admins.snapshots().map((s) => s.docs
        .map((d) => AdminUser.fromFirestore(d.id, d.data()))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  /// Mevcut kullanıcının admin doc'u.
  Future<AdminUser?> getCurrent() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _admins.doc(user.uid).get();
    if (!snap.exists) return null;
    return AdminUser.fromFirestore(snap.id, snap.data()!);
  }

  /// Yeni admin oluştur (secondary app ile, ana session bozulmaz).
  /// Sadece super_admin çağırmalı (UI/rules ile kontrol edilir).
  Future<AdminUser> create({
    required String email,
    required String password,
    required AdminRole role,
  }) async {
    final currentUid = _auth.currentUser?.uid;

    // Geçici secondary app — ana auth session'ını korur
    FirebaseApp? secondary;
    try {
      secondary = await Firebase.initializeApp(
        name: 'admin-create-${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondary);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final newUid = cred.user!.uid;

      final user = AdminUser(
        uid: newUid,
        email: email.trim(),
        role: role,
        active: true,
        createdAt: DateTime.now(),
        createdBy: currentUid,
      );
      await _admins.doc(newUid).set(user.toFirestore());

      await secondaryAuth.signOut();
      return user;
    } finally {
      if (secondary != null) {
        await secondary.delete();
      }
    }
  }

  /// Admin'i pasif/aktif yap (silmek yerine — referansları korumak için).
  Future<void> setActive(String uid, bool active) async {
    await _admins.doc(uid).update({'active': active});
  }

  /// Rol değiştir.
  Future<void> setRole(String uid, AdminRole role) async {
    await _admins.doc(uid).update({'role': role.id});
  }

  /// Admin dokümanını sil (Firestore'dan kaldırır; auth hesabı kalır ama erişim kalkar).
  Future<void> delete(String uid) async {
    await _admins.doc(uid).delete();
  }

  /// Son giriş zamanını güncelle.
  Future<void> touchLastLogin() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _admins.doc(user.uid).set(
      {'lastLoginAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
