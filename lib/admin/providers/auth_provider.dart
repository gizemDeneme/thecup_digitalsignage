import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => getIt<AuthService>());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final signInProvider = FutureProvider.family<void, ({String email, String password})>(
  (ref, creds) async {
    await ref.read(authServiceProvider).signIn(creds.email, creds.password);
  },
);
