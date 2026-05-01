import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/screen_model.dart';
import '../../providers/screen_provider.dart';
import 'screen_playlist_screen.dart';

class ScreensListScreen extends ConsumerWidget {
  const ScreensListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screensAsync = ref.watch(allScreensProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: screensAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.kraft)),
        error: (e, _) => Center(
            child: Text('Hata: $e', style: const TextStyle(color: AppColors.ink))),
        data: (screens) {
          if (screens.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tv_off_outlined, size: 48, color: AppColors.muted),
                  SizedBox(height: 12),
                  Text(
                    'Henüz kayıtlı ekran yok.\nTV\'lerde uygulama açık olmalı.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: screens.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ScreenTile(screen: screens[i]),
          );
        },
      ),
    );
  }
}

class _ScreenTile extends ConsumerWidget {
  final ScreenModel screen;
  const _ScreenTile({required this.screen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPlaylist = screen.playlist != null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenPlaylistScreen(screen: screen),
        ),
      ),
      onLongPress: () => _renameDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.line.withValues(alpha: 0.08), width: 1),
        ),
        child: Row(
          children: [
            // Online badge
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: screen.isOnline ? AppColors.success : AppColors.muted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            // TV icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.kraft.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tv_outlined,
                  color: AppColors.kraft, size: 22),
            ),
            const SizedBox(width: 14),
            // Name + last seen
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    screen.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Son görülme: ${screen.lastSeenLabel}',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Playlist status
            if (hasPlaylist)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${screen.playlist!.items.length} içerik',
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'boş',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Future<void> _renameDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: screen.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.paper2,
        title: const Text('Ekranı Yeniden Adlandır',
            style: TextStyle(color: AppColors.ink)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.paper,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal',
                  style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kraft,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child:
                const Text('Kaydet', style: TextStyle(color: AppColors.ink)),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await ref
          .read(screenRepositoryProvider)
          .updateName(screen.deviceId, newName);
    }
  }
}
