import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/content_item_model.dart';
import '../../providers/content_provider.dart';
import 'upload_video_screen.dart';
import 'upload_image_screen.dart';
import 'create_menu_screen.dart';
import 'create_price_list_screen.dart';

class ContentLibraryScreen extends ConsumerStatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  ConsumerState<ContentLibraryScreen> createState() =>
      _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends ConsumerState<ContentLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = [
    (type: ContentType.video, label: 'Videolar', icon: Icons.videocam),
    (type: ContentType.image, label: 'Görseller', icon: Icons.image),
    (type: ContentType.menu, label: 'Menüler', icon: Icons.menu_book),
    (type: ContentType.priceList, label: 'Listeler', icon: Icons.list_alt),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFE94560),
          labelColor: const Color(0xFFE94560),
          unselectedLabelColor: Colors.white54,
          tabs: _tabs
              .map((t) => Tab(icon: Icon(t.icon), text: t.label))
              .toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabs
                .map((t) => _ContentTab(
                      type: t.type,
                      onAdd: () => _navigateToAdd(context, t.type),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _navigateToAdd(BuildContext context, ContentType type) {
    final screen = switch (type) {
      ContentType.video => const UploadVideoScreen(),
      ContentType.image => const UploadImageScreen(),
      ContentType.menu => const CreateMenuScreen(),
      ContentType.priceList => const CreatePriceListScreen(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _ContentTab extends ConsumerWidget {
  final ContentType type;
  final VoidCallback onAdd;

  const _ContentTab({required this.type, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(contentByTypeProvider(type));
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        backgroundColor: const Color(0xFFE94560),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: items.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Color(0xFFE94560))),
        error: (e, _) => Center(
            child: Text(e.toString(), style: const TextStyle(color: Colors.white))),
        data: (list) => list.isEmpty
            ? const Center(
                child: Text('Henüz içerik yok',
                    style: TextStyle(color: Colors.white54)))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => _ContentCard(item: list[i]),
              ),
      ),
    );
  }
}

class _ContentCard extends ConsumerWidget {
  final ContentItemModel item;

  const _ContentCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _thumbnail()),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFE94560), size: 20),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail() {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(12)),
      child: switch (item) {
        VideoItemModel v when v.thumbnailUrl != null =>
          CachedNetworkImage(
              imageUrl: v.thumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity),
        ImageItemModel img => CachedNetworkImage(
            imageUrl: img.downloadUrl,
            fit: BoxFit.cover,
            width: double.infinity),
        _ => Container(
            color: const Color(0xFF0F3460),
            child: Center(
              child: Icon(
                item.type == ContentType.menu
                    ? Icons.menu_book
                    : Icons.list_alt,
                color: const Color(0xFFE94560),
                size: 48,
              ),
            ),
          ),
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Sil', style: TextStyle(color: Colors.white)),
        content: Text('"${item.title}" silinsin mi?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('İptal', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil',
                  style: TextStyle(color: Color(0xFFE94560)))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(uploadNotifierProvider.notifier).delete(item);
    }
  }
}
