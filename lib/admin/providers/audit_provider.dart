import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/services/audit_service.dart';

final auditServiceProvider = Provider<AuditService>((ref) => getIt<AuditService>());

final auditLogsStreamProvider = StreamProvider<List<AuditLog>>((ref) {
  return ref.read(auditServiceProvider).watchRecent();
});
