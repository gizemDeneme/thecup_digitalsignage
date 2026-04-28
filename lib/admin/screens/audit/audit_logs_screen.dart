import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/audit_log_model.dart';
import '../../providers/audit_provider.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  String _userFilter = '';
  AuditAction? _actionFilter;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsStreamProvider);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(
        children: [
          _FilterBar(
            actionFilter: _actionFilter,
            userFilter: _userFilter,
            onAction: (a) => setState(() => _actionFilter = a),
            onUser: (u) => setState(() => _userFilter = u),
          ),
          const Divider(height: 1),
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.kraft)),
              error: (e, _) => Center(
                  child: Text('Hata: $e',
                      style: const TextStyle(color: AppColors.ink))),
              data: (logs) {
                final filtered = logs.where((l) {
                  if (_actionFilter != null && l.action != _actionFilter) {
                    return false;
                  }
                  if (_userFilter.isNotEmpty &&
                      !l.userEmail
                          .toLowerCase()
                          .contains(_userFilter.toLowerCase())) {
                    return false;
                  }
                  return true;
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Kayıt bulunamadı.',
                        style: TextStyle(color: AppColors.muted)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _LogTile(log: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final AuditAction? actionFilter;
  final String userFilter;
  final ValueChanged<AuditAction?> onAction;
  final ValueChanged<String> onUser;

  const _FilterBar({
    required this.actionFilter,
    required this.userFilter,
    required this.onAction,
    required this.onUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'kullanıcı (e-posta) ara...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: onUser,
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: DropdownButtonFormField<AuditAction?>(
              initialValue: actionFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'aksiyon',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('tüm aksiyonlar')),
                ...AuditAction.values
                    .where((a) => a != AuditAction.unknown)
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.label, overflow: TextOverflow.ellipsis),
                        )),
              ],
              onChanged: onAction,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AuditLog log;
  const _LogTile({required this.log});

  IconData _iconFor(AuditAction a) {
    switch (a) {
      case AuditAction.signIn:
        return Icons.login;
      case AuditAction.signOut:
        return Icons.logout;
      case AuditAction.contentUpload:
        return Icons.cloud_upload_outlined;
      case AuditAction.contentUpdate:
        return Icons.edit_outlined;
      case AuditAction.contentDelete:
        return Icons.delete_outline;
      case AuditAction.playlistPublish:
        return Icons.broadcast_on_personal_outlined;
      case AuditAction.userCreate:
        return Icons.person_add_alt_1_outlined;
      case AuditAction.userDisable:
        return Icons.person_off_outlined;
      case AuditAction.userEnable:
        return Icons.person_outline;
      case AuditAction.unknown:
        return Icons.help_outline;
    }
  }

  Color _colorFor(AuditAction a) {
    switch (a) {
      case AuditAction.contentDelete:
      case AuditAction.userDisable:
        return AppColors.danger;
      case AuditAction.playlistPublish:
        return AppColors.kraft2;
      case AuditAction.signIn:
      case AuditAction.userCreate:
      case AuditAction.userEnable:
        return AppColors.success;
      default:
        return AppColors.ink2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM, HH:mm:ss');
    final color = _colorFor(log.action);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.line.withValues(alpha: 0.06), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(_iconFor(log.action), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(log.userEmail.isEmpty ? '—' : log.userEmail,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                    Text('•',
                        style: TextStyle(
                            color: AppColors.muted.withValues(alpha: 0.5),
                            fontSize: 11)),
                    Text(log.action.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                    if (log.targetName != null && log.targetName!.isNotEmpty)
                      Text('"${log.targetName}"',
                          style: const TextStyle(
                            color: AppColors.ink2,
                            fontSize: 13,
                          )),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  df.format(log.timestamp.toLocal()),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
