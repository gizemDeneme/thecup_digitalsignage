import 'package:cloud_firestore/cloud_firestore.dart';

/// `admins/{uid}` koleksiyonundaki kullanıcı kaydı.
class AdminUser {
  final String uid;
  final String email;
  final AdminRole role;
  final bool active;
  final DateTime createdAt;
  final String? createdBy;     // hangi admin ekledi (uid)
  final DateTime? lastLoginAt;

  const AdminUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.active,
    required this.createdAt,
    this.createdBy,
    this.lastLoginAt,
  });

  factory AdminUser.fromFirestore(String uid, Map<String, dynamic> data) {
    return AdminUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      role: AdminRole.parse(data['role'] as String?),
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String?,
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'role': role.id,
        'active': active,
        'createdAt': createdAt,
        if (createdBy != null) 'createdBy': createdBy,
        if (lastLoginAt != null) 'lastLoginAt': lastLoginAt,
      };
}

enum AdminRole {
  superAdmin('super_admin', 'Süper Admin'),
  admin('admin', 'Admin');

  final String id;
  final String label;
  const AdminRole(this.id, this.label);

  static AdminRole parse(String? raw) {
    return AdminRole.values
        .firstWhere((r) => r.id == raw, orElse: () => AdminRole.admin);
  }
}
