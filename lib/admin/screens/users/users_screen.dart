import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_user_model.dart';
import '../../../data/models/audit_log_model.dart';
import '../../providers/admin_user_provider.dart';
import '../../providers/audit_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersStreamProvider);
    final currentAdmin = ref.watch(currentAdminProvider).value;
    final isSuperAdmin = currentAdmin?.role == AdminRole.superAdmin;

    return Scaffold(
      backgroundColor: AppColors.paper,
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, ref),
              backgroundColor: AppColors.kraft,
              foregroundColor: AppColors.paper,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('yeni kullanıcı'),
            )
          : null,
      body: usersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.kraft)),
        error: (e, _) =>
            Center(child: Text('Hata: $e', style: const TextStyle(color: AppColors.ink))),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text('Henüz kullanıcı kaydı yok.',
                  style: TextStyle(color: AppColors.muted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _UserCard(
              user: users[i],
              currentUid: currentAdmin?.uid,
              canManage: isSuperAdmin,
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    AdminRole role = AdminRole.admin;
    bool loading = false;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('yeni kullanıcı'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'e-posta'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'geçici şifre (min. 6 karakter)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AdminRole>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'rol'),
                  items: AdminRole.values
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.label),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => role = v ?? AdminRole.admin),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('iptal'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setLocal(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        final user =
                            await ref.read(adminUserServiceProvider).create(
                                  email: emailCtrl.text.trim(),
                                  password: passCtrl.text,
                                  role: role,
                                );
                        await ref.read(auditServiceProvider).log(
                              AuditAction.userCreate,
                              targetType: 'user',
                              targetId: user.uid,
                              targetName: user.email,
                              metadata: {'role': role.id},
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setLocal(() {
                          loading = false;
                          error = e.toString();
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kraft,
                foregroundColor: AppColors.paper,
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.paper, strokeWidth: 2))
                  : const Text('oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final AdminUser user;
  final String? currentUid;
  final bool canManage;

  const _UserCard({
    required this.user,
    required this.currentUid,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelf = user.uid == currentUid;
    final df = DateFormat('dd MMM yyyy, HH:mm');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.line.withValues(alpha: 0.08), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                user.role == AdminRole.superAdmin ? AppColors.ink : AppColors.kraft,
            child: Text(
              user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.paper, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      _Tag(text: 'sen', color: AppColors.kraft),
                    ],
                    const SizedBox(width: 6),
                    _Tag(
                      text: user.role.label,
                      color: user.role == AdminRole.superAdmin
                          ? AppColors.ink
                          : AppColors.kraft2,
                    ),
                    if (!user.active) ...[
                      const SizedBox(width: 6),
                      _Tag(text: 'pasif', color: AppColors.danger),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'eklendi: ${df.format(user.createdAt.toLocal())}',
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12),
                ),
                if (user.lastLoginAt != null)
                  Text(
                    'son giriş: ${df.format(user.lastLoginAt!.toLocal())}',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (canManage && !isSelf) ...[
            IconButton(
              tooltip: 'düzenle',
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.ink2,
              onPressed: () => _showEditDialog(context, ref),
            ),
            IconButton(
              tooltip: 'sil',
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.danger,
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    AdminRole selectedRole = user.role;
    bool selectedActive = user.active;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(user.email,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<AdminRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'rol'),
                  items: AdminRole.values
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.label),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setLocal(() => selectedRole = v ?? AdminRole.admin),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                        child: Text('Hesap aktif',
                            style: TextStyle(color: AppColors.ink))),
                    Switch(
                      value: selectedActive,
                      activeColor: AppColors.kraft,
                      onChanged: (v) => setLocal(() => selectedActive = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('iptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kraft,
                foregroundColor: AppColors.paper,
              ),
              onPressed: () async {
                final svc = ref.read(adminUserServiceProvider);
                final audit = ref.read(auditServiceProvider);

                if (selectedRole != user.role) {
                  await svc.setRole(user.uid, selectedRole);
                  await audit.log(
                    AuditAction.contentUpdate,
                    targetType: 'user.role',
                    targetId: user.uid,
                    targetName: user.email,
                    metadata: {
                      'oldRole': user.role.id,
                      'newRole': selectedRole.id,
                    },
                  );
                }
                if (selectedActive != user.active) {
                  await svc.setActive(user.uid, selectedActive);
                  await audit.log(
                    selectedActive
                        ? AuditAction.userEnable
                        : AuditAction.userDisable,
                    targetType: 'user',
                    targetId: user.uid,
                    targetName: user.email,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('kullanıcıyı sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.5),
                children: [
                  const TextSpan(text: '"'),
                  TextSpan(
                    text: user.email,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '" admin paneline erişimini kaybedecek.'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu işlem geri alınamaz.',
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.paper,
            ),
            child: const Text('sil'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(adminUserServiceProvider).delete(user.uid);
      await ref.read(auditServiceProvider).log(
            AuditAction.userDisable,
            targetType: 'user',
            targetId: user.uid,
            targetName: user.email,
            metadata: {'action': 'deleted'},
          );
    }
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
