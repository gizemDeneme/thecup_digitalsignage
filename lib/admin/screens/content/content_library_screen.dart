import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
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
    (type: ContentType.video, label: 'videolar', icon: Icons.videocam_outlined),
    (type: ContentType.image, label: 'görseller', icon: Icons.image_outlined),
    (type: ContentType.menu, label: 'menüler', icon: Icons.menu_book_outlined),
    (type: ContentType.priceList, label: 'listeler', icon: Icons.list_alt_outlined),
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
        Container(
          color: AppColors.paper,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _tabs
                .map((t) => Tab(icon: Icon(t.icon, size: 20), text: t.label))
                .toList(),
          ),
        ),
        const Divider(height: 1),
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
      backgroundColor: AppColors.paper,
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      body: items.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.kraft)),
        error: (e, _) => Center(
            child:
                Text('Hata: $e', style: const TextStyle(color: AppColors.ink))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
                child: Text('henüz içerik yok',
                    style: TextStyle(color: AppColors.muted)));
          }
          final w = MediaQuery.of(context).size.width;
          final cols = w < 480
              ? 1
              : w < 900
                  ? 2
                  : w < 1300
                      ? 3
                      : 4;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => _ContentCard(item: list[i]),
          );
        },
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
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.line.withValues(alpha: 0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _thumbnail()),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger),
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: switch (item) {
        VideoItemModel v when v.thumbnailUrl != null => CachedNetworkImage(
            imageUrl: v.thumbnailUrl!,
            fit: BoxFit.cover,
            width: double.infinity),
        ImageItemModel img => CachedNetworkImage(
            imageUrl: img.downloadUrl,
            fit: BoxFit.cover,
            width: double.infinity),
        VideoItemModel _ => Container(
            color: AppColors.ink,
            child: const Center(
              child: Icon(Icons.videocam_outlined,
                  color: AppColors.paper, size: 48),
            ),
          ),
        MenuItemModel _ => Container(
            color: AppColors.kraft,
            child: const Center(
              child: Icon(Icons.menu_book_outlined,
                  color: AppColors.paper, size: 48),
            ),
          ),
        PriceListModel _ => Container(
            color: AppColors.kraft2,
            child: const Center(
              child: Icon(Icons.list_alt_outlined,
                  color: AppColors.paper, size: 48),
            ),
          ),
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('sil'),
        content: Text('"${item.title}" silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('iptal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('sil')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(uploadNotifierProvider.notifier).delete(item);
    }
  }
}
