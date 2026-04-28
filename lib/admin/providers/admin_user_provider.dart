import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/services/admin_user_service.dart';

final adminUserServiceProvider =
    Provider<AdminUserService>((ref) => getIt<AdminUserService>());

final adminUsersStreamProvider = StreamProvider<List<AdminUser>>((ref) {
  return ref.read(adminUserServiceProvider).watchAll();
});

/// Mevcut kullanıcının admin doc'u (rol kontrolü için).
final currentAdminProvider = FutureProvider<AdminUser?>((ref) {
  return ref.read(adminUserServiceProvider).getCurrent();
});
