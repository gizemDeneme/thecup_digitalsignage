import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/content_item_model.dart';
import '../../providers/content_provider.dart';
import '../../providers/playlist_provider.dart';
import 'publish_screen.dart';

class PlaylistEditorScreen extends ConsumerWidget {
  const PlaylistEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(playlistEditorProvider);
    final totalSecs = ref.watch(
        playlistEditorProvider.select((s) => s.fold(0, (a, b) => a + b.durationSeconds)));
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add_content',
            onPressed: () => _showContentPicker(context, ref),
            backgroundColor: const Color(0xFF0F3460),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'publish',
            onPressed: items.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PublishScreen()),
                    ),
            backgroundColor: const Color(0xFFE94560),
            icon: const Icon(Icons.broadcast_on_personal, color: Colors.white),
            label: const Text('Yayınla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Playlist boş.\n+ ile içerik ekleyin.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${items.length} içerik',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Toplam: ${mins}d ${secs}s',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    onReorder: (o, n) {
                      ref
                          .read(playlistEditorProvider.notifier)
                          .reorder(o, n > o ? n - 1 : n);
                    },
                    itemBuilder: (_, i) => _PlaylistItemTile(
                      key: ValueKey(items[i].id),
                      index: i,
                      item: items[i],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showContentPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
      builder: (_) => const _ContentPickerSheet(),
    );
  }
}

class _PlaylistItemTile extends ConsumerWidget {
  final int index;
  final PlaylistItem item;

  const _PlaylistItemTile({super.key, required this.index, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeIcon = switch (item.type) {
      ContentType.video => Icons.videocam,
      ContentType.image => Icons.image,
      ContentType.menu => Icons.menu_book,
      ContentType.priceList => Icons.list_alt,
    };
    final typeLabel = switch (item.type) {
      ContentType.video => 'Video',
      ContentType.image => 'Görsel',
      ContentType.menu => 'Menü',
      ContentType.priceList => 'Liste',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: Colors.white38),
          const SizedBox(width: 8),
          Icon(typeIcon, color: const Color(0xFFE94560), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.contentRef.split('/').last,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(typeLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.durationSeconds.toString(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) {
                      final secs = int.tryParse(v);
                      if (secs != null && secs > 0) {
                        ref
                            .read(playlistEditorProvider.notifier)
                            .updateDuration(index, secs);
                      }
                    },
                  ),
                ),
                const Text('s', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE94560)),
            onPressed: () =>
                ref.read(playlistEditorProvider.notifier).removeAt(index),
          ),
        ],
      ),
    );
  }
}

class _ContentPickerSheet extends ConsumerStatefulWidget {
  const _ContentPickerSheet();

  @override
  ConsumerState<_ContentPickerSheet> createState() =>
      _ContentPickerSheetState();
}

class _ContentPickerSheetState extends ConsumerState<_ContentPickerSheet> {
  ContentType _selectedType = ContentType.video;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(contentByTypeProvider(_selectedType));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ContentType.video,
                ContentType.image,
                ContentType.menu,
                ContentType.priceList,
              ]
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_typeLabel(t)),
                          selected: _selectedType == t,
                          onSelected: (_) =>
                              setState(() => _selectedType = t),
                          selectedColor: const Color(0xFFE94560),
                          labelStyle: TextStyle(
                              color: _selectedType == t
                                  ? Colors.white
                                  : Colors.white70),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFE94560))),
              error: (e, _) => Center(
                  child: Text(e.toString(),
                      style: const TextStyle(color: Colors.white))),
              data: (list) => ListView.builder(
                controller: ctrl,
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                  leading: Icon(
                    _typeIcon(list[i].type),
                    color: const Color(0xFFE94560),
                  ),
                  title: Text(list[i].title,
                      style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    ref
                        .read(playlistEditorProvider.notifier)
                        .addItem(list[i]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(ContentType t) => switch (t) {
        ContentType.video => 'Videolar',
        ContentType.image => 'Görseller',
        ContentType.menu => 'Menüler',
        ContentType.priceList => 'Listeler',
      };

  IconData _typeIcon(ContentType t) => switch (t) {
        ContentType.video => Icons.videocam,
        ContentType.image => Icons.image,
        ContentType.menu => Icons.menu_book,
        ContentType.priceList => Icons.list_alt,
      };
}
