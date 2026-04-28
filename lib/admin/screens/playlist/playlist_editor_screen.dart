import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
      backgroundColor: AppColors.paper,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add_content',
            onPressed: () => _showContentPicker(context, ref),
            backgroundColor: AppColors.paper2,
            child: const Icon(Icons.add, color: AppColors.ink),
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
            backgroundColor: AppColors.kraft,
            icon: const Icon(Icons.broadcast_on_personal, color: AppColors.ink),
            label: const Text('Yayınla', style: TextStyle(color: AppColors.ink)),
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
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
      backgroundColor: AppColors.paper2,
      builder: (_) => const _ContentPickerSheet(),
    );
  }
}

// ─── Playlist Item Tile ───────────────────────────────────────────────────────

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

    final hasSchedule = item.startMinutes != null;
    final contentId = item.contentRef.split('/').last;
    final titleMap = ref.watch(contentTitleMapProvider).value ?? {};
    final displayTitle = titleMap[contentId] ?? contentId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(8),
        border: hasSchedule
            ? Border.all(color: AppColors.kraft.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main row ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
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
                // Duration field
                SizedBox(
                  width: 64,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: item.durationSeconds.toString(),
                          style: const TextStyle(color: AppColors.ink, fontSize: 14),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) {
                            final s = int.tryParse(v);
                            if (s != null && s > 0) {
                              ref
                                  .read(playlistEditorProvider.notifier)
                                  .updateDuration(index, s);
                            }
                          },
                        ),
                      ),
                      const Text('s', style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.kraft, size: 20),
                  onPressed: () =>
                      ref.read(playlistEditorProvider.notifier).removeAt(index),
                ),
              ],
            ),
          ),
          // ── Time range row ────────────────────────────────────────────────
          GestureDetector(
            onTap: () => _showTimePicker(context, ref),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: hasSchedule
                    ? AppColors.kraft.withValues(alpha: 0.15)
                    : AppColors.paper2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: hasSchedule
                      ? AppColors.kraft
                      : AppColors.line.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasSchedule ? Icons.schedule : Icons.all_inclusive,
                        color: hasSchedule
                            ? AppColors.kraft
                            : AppColors.ink2,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.timeRangeLabel,
                        style: TextStyle(
                          color: hasSchedule
                              ? AppColors.kraft
                              : AppColors.ink2,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.edit, color: AppColors.muted, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(playlistEditorProvider.notifier);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TimeRangeSheet(
        item: item,
        onSave: (start, end) => notifier.updateTimeRange(index, start, end),
        onClear: () => notifier.clearTimeRange(index),
      ),
    );
  }
}

// ─── Time Range Bottom Sheet ──────────────────────────────────────────────────

class _TimeRangeSheet extends StatefulWidget {
  final PlaylistItem item;
  final void Function(int startMinutes, int endMinutes) onSave;
  final VoidCallback onClear;

  const _TimeRangeSheet({
    required this.item,
    required this.onSave,
    required this.onClear,
  });

  @override
  State<_TimeRangeSheet> createState() => _TimeRangeSheetState();
}

class _TimeRangeSheetState extends State<_TimeRangeSheet> {
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _hasSchedule = false;

  @override
  void initState() {
    super.initState();
    _hasSchedule = widget.item.startMinutes != null;
    _start = widget.item.startMinutes != null
        ? TimeOfDay(
            hour: widget.item.startMinutes! ~/ 60,
            minute: widget.item.startMinutes! % 60)
        : const TimeOfDay(hour: 8, minute: 0);
    _end = widget.item.endMinutes != null
        ? TimeOfDay(
            hour: widget.item.endMinutes! ~/ 60,
            minute: widget.item.endMinutes! % 60)
        : const TimeOfDay(hour: 17, minute: 0);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.kraft,
            surface: AppColors.paper2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yayın Zamanlaması',
            style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Toggle
          Row(
            children: [
              Expanded(
                child: _OptionTile(
                  label: 'Her Zaman',
                  icon: Icons.all_inclusive,
                  selected: !_hasSchedule,
                  onTap: () => setState(() => _hasSchedule = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionTile(
                  label: 'Belirli Saatler',
                  icon: Icons.schedule,
                  selected: _hasSchedule,
                  onTap: () => setState(() => _hasSchedule = true),
                ),
              ),
            ],
          ),
          // Time pickers (only when scheduled)
          if (_hasSchedule) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: 'Başlangıç',
                    time: _fmt(_start),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('–',
                      style: TextStyle(color: AppColors.muted, fontSize: 24)),
                ),
                Expanded(
                  child: _TimeTile(
                    label: 'Bitiş',
                    time: _fmt(_end),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Midnight-crossing hint
            if (_end.hour * 60 + _end.minute <=
                _start.hour * 60 + _start.minute)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.kraft, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Gece yarısını geçiyor (ertesi güne kadar)',
                      style: TextStyle(
                          color: AppColors.kraft, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_hasSchedule) {
                  widget.onSave(
                    _start.hour * 60 + _start.minute,
                    _end.hour * 60 + _end.minute,
                  );
                } else {
                  widget.onClear();
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kraft,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Kaydet',
                  style: TextStyle(fontSize: 16, color: AppColors.ink)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.kraft.withValues(alpha: 0.15)
              : AppColors.paper2,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: AppColors.kraft)
              : null,
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.kraft : AppColors.muted),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? AppColors.kraft
                        : AppColors.muted,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.paper2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(time,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
      ),
    );
  }
}

// ─── Content Picker Sheet ─────────────────────────────────────────────────────

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
                          selectedColor: AppColors.kraft,
                          labelStyle: TextStyle(
                              color: _selectedType == t
                                  ? Colors.white
                                  : AppColors.ink2),
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
                      color: AppColors.kraft)),
              error: (e, _) => Center(
                  child: Text(e.toString(),
                      style: const TextStyle(color: AppColors.ink))),
              data: (list) => ListView.builder(
                controller: ctrl,
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                  leading: Icon(_typeIcon(list[i].type),
                      color: AppColors.kraft),
                  title: Text(list[i].title,
                      style: const TextStyle(color: AppColors.ink)),
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
