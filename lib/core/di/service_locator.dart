import 'package:get_it/get_it.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/playlist_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  getIt.registerLazySingleton(() => FirestoreService());
  getIt.registerLazySingleton(() => StorageService());
  getIt.registerLazySingleton(() => AuthService(getIt<FirestoreService>()));
  getIt.registerLazySingleton(
      () => ContentRepository(getIt<FirestoreService>(), getIt<StorageService>()));
  getIt.registerLazySingleton(
      () => PlaylistRepository(getIt<FirestoreService>()));
}
