import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/content_item_model.dart';
import '../../../data/models/screen_group_model.dart';
import '../../providers/content_provider.dart';
import '../../providers/screen_provider.dart';
import '../../providers/audit_provider.dart';
import '../../../data/models/audit_log_model.dart';

class ScreenPlaylistScreen extends ConsumerWidget {
  final ScreenGroupModel group;
  const ScreenPlaylistScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(groupEditorProvider(group.id));
    final totalSecs = items.fold<int>(0, (a, b) => a + b.durationSeconds);
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper2,
        title: Text(group.name,
            style: const TextStyle(color: AppColors.ink)),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'group_add_content_${group.id}',
            onPressed: () => _showContentPicker(context, ref),
            backgroundColor: AppColors.paper2,
            child: const Icon(Icons.add, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'group_publish_${group.id}',
            onPressed:
                items.isEmpty ? null : () => _publish(context, ref, items),
            backgroundColor: AppColors.kraft,
            icon: const Icon(Icons.broadcast_on_personal,
                color: AppColors.ink),
            label: Text('Tüm ${group.name} Ekranlarına Yayınla',
                style: const TextStyle(color: AppColors.ink)),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Playlist boş.\n+ ile içerik ekleyin.',
                style: TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${items.length} içerik',
                          style: const TextStyle(color: AppColors.ink2)),
                      Text('Toplam: ${mins}d ${secs}s',
                          style: const TextStyle(color: AppColors.ink2)),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: items.length,
                    onReorder: (o, n) {
                      ref
                          .read(groupEditorProvider(group.id).notifier)
                          .reorder(o, n > o ? n - 1 : n);
                    },
                    itemBuilder: (_, i) => _GroupPlaylistItemTile(
                      key: ValueKey(items[i].id),
                      index: i,
                      item: items[i],
                      groupId: group.id,
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
      backgroundColor: AppColors.paper2,
      builder: (_) => _GroupContentPickerSheet(groupId: group.id),
    );
  }

  Future<void> _publish(BuildContext context, WidgetRef ref,
      List<PlaylistItem> items) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.kraft)),
    );
    try {
      await ref
          .read(screenRepositoryProvider)
          .publishToGroup(group.id, items);
      await ref.read(auditServiceProvider).log(
            AuditAction.playlistPublish,
            targetId: group.id,
            targetName: group.name,
            metadata: {
              'groupId': group.id,
              'itemCount': items.length,
              'totalSeconds':
                  items.fold<int>(0, (a, b) => a + b.durationSeconds),
            },
          );
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${group.name} — tüm ekranlara yayınlandı!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

// ─── Item Tile ────────────────────────────────────────────────────────────────

class _GroupPlaylistItemTile extends ConsumerWidget {
  final int index;
  final PlaylistItem item;
  final String groupId;

  const _GroupPlaylistItemTile({
    super.key,
    required this.index,
    required this.item,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeIcon = switch (item.type) {
      ContentType.video => Icons.videocam,
      ContentType.image => Icons.image,
      ContentType.menu => Icons.menu_book,
      ContentType.priceList => Icons.list_alt,
    };

    final contentId = item.contentRef.split('/').last;
    final titleMap = ref.watch(contentTitleMapProvider).value ?? {};
    final displayTitle = titleMap[contentId] ?? contentId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        child: Row(
          children: [
            const Icon(Icons.drag_handle, color: AppColors.muted),
            const SizedBox(width: 8),
            Icon(typeIcon, color: AppColors.kraft, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayTitle,
                style: const TextStyle(color: AppColors.ink2, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 64,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: item.durationSeconds.toString(),
                      style: const TextStyle(
                          color: AppColors.ink, fontSize: 14),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) {
                        final s = int.tryParse(v);
                        if (s != null && s > 0) {
                          ref
                              .read(groupEditorProvider(groupId).notifier)
                              .updateDuration(index, s);
                        }
                      },
                    ),
                  ),
                  const Text('s',
                      style: TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.kraft, size: 20),
              onPressed: () => ref
                  .read(groupEditorProvider(groupId).notifier)
                  .removeAt(index),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Content Picker ───────────────────────────────────────────────────────────

class _GroupContentPickerSheet extends ConsumerStatefulWidget {
  final String groupId;
  const _GroupContentPickerSheet({required this.groupId});

  @override
  ConsumerState<_GroupContentPickerSheet> createState() =>
      _GroupContentPickerSheetState();
}

class _GroupContentPickerSheetState
    extends ConsumerState<_GroupContentPickerSheet> {
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
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.line.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ContentType.video, ContentType.image,
                ContentType.menu, ContentType.priceList,
              ].map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_typeLabel(t)),
                      selected: _selectedType == t,
                      onSelected: (_) =>
                          setState(() => _selectedType = t),
                      selectedColor: AppColors.kraft,
                      labelStyle: TextStyle(
                          color: _selectedType == t
                              ? Colors.white
                              : AppColors.ink2),
                    ),
                  )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.kraft)),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) => ListView.builder(
                controller: ctrl,
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                  leading:
                      Icon(_typeIcon(list[i].type), color: AppColors.kraft),
                  title: Text(list[i].title,
                      style: const TextStyle(color: AppColors.ink)),
                  onTap: () {
                    ref
                        .read(groupEditorProvider(widget.groupId).notifier)
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
