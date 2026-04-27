import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/content_item_model.dart';
import '../controllers/playlist_controller.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/image_display_widget.dart';
import '../widgets/menu_display_widget.dart';
import '../widgets/price_list_widget.dart';

class DisplayScreen extends ConsumerStatefulWidget {
  const DisplayScreen({super.key});

  @override
  ConsumerState<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends ConsumerState<DisplayScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Load from cache immediately for instant display
    ref.read(playlistControllerProvider.notifier).loadFromCache();

    // Start listening to Firestore with timeout fallback
    ref.listenManual(
      playlistStreamProvider,
      (_, next) {
        next.whenData((playlist) {
          ref
              .read(playlistControllerProvider.notifier)
              .onPlaylistUpdate(playlist);
        });
        if (next.hasError) {
          ref.read(playlistControllerProvider.notifier).setOffline(true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playlistControllerProvider);
    final item = state.currentItem;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (item == null)
            const _WaitingScreen()
          else
            _buildContent(item),
          if (state.isOffline)
            const Positioned(
              top: 16,
              right: 16,
              child: _OfflineBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(PlaylistItem item) {
    final contentId = item.contentRef.split('/').last;
    final contentAsync = ref.watch(contentItemProvider(contentId));

    return contentAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white24)),
      error: (_, __) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white24, size: 80)),
      data: (content) {
        if (content == null) {
          return const Center(
              child: Icon(Icons.broken_image, color: Colors.white24, size: 80));
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: switch (content) {
            VideoItemModel v => VideoPlayerWidget(key: ValueKey(v.id), item: v),
            ImageItemModel img =>
              ImageDisplayWidget(key: ValueKey(img.id), item: img),
            MenuItemModel m =>
              MenuDisplayWidget(key: ValueKey(m.id), item: m),
            PriceListModel p => PriceListWidget(key: ValueKey(p.id), item: p),
          },
        );
      },
    );
  }
}

class _WaitingScreen extends StatelessWidget {
  const _WaitingScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'thecup',
              style: TextStyle(
                color: Color(0xFFE94560),
                fontSize: 72,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'İçerik bekleniyor...',
              style: TextStyle(color: Colors.white38, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, color: Colors.white38, size: 14),
          SizedBox(width: 4),
          Text('NO SIGNAL',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
