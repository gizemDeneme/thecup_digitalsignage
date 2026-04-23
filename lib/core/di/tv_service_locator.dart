import '../../tv/services/cache_service.dart';
import 'service_locator.dart';

Future<void> setupTvServiceLocator() async {
  final cache = CacheService();
  await cache.init();
  getIt.registerSingleton<CacheService>(cache);
}
