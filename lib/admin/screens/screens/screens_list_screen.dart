import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/content_item_model.dart';
import '../../../data/models/screen_model.dart';
import '../../../data/models/screen_group_model.dart';
import '../../providers/content_provider.dart';
import '../../providers/screen_provider.dart';
import 'screen_playlist_screen.dart';

final _contentByIdProvider =
    FutureProvider.autoDispose.family<ContentItemModel?, String>(
  (ref, id) => ref.read(contentRepositoryProvider).getById(id),
);

class ScreensListScreen extends ConsumerStatefulWidget {
  const ScreensListScreen({super.key});

  @override
  ConsumerState<ScreensListScreen> createState() => _ScreensListScreenState();
}

class _ScreensListScreenState extends ConsumerState<ScreensListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showDevices = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Grupları Firestore'da oluştur (yoksa)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(screenRepositoryProvider).ensureDefaultGroups();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(allGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(
        children: [
          // Tab bar: Ekran 1 / Ekran 2
          Container(
            color: AppColors.paper,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.tv_outlined, size: 20), text: 'Ekran 1'),
                Tab(icon: Icon(Icons.tv_outlined, size: 20), text: 'Ekran 2'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.kraft)),
              error: (e, _) => Center(child: Text('$e')),
              data: (groups) {
                // Grupları sırala (ekran_1 önce)
                final sorted = [...groups]
                  ..sort((a, b) => a.id.compareTo(b.id));
                // 2 grup garantile
                while (sorted.length < 2) {
                  sorted.add(ScreenGroupModel(
                      id: sorted.isEmpty ? 'ekran_1' : 'ekran_2',
                      name: sorted.isEmpty ? 'Ekran 1' : 'Ekran 2'));
                }
                return TabBarView(
                  controller: _tabController,
                  children: sorted
                      .take(2)
                      .map((g) => _GroupTab(group: g))
                      .toList(),
                );
              },
            ),
          ),
          // Cihazlar bölümü (toggle)
          _DevicesPanel(isOpen: _showDevices,
              onToggle: () => setState(() => _showDevices = !_showDevices)),
        ],
      ),
    );
  }
}

// ─── Grup Sekmesi ─────────────────────────────────────────────────────────────

class _GroupTab extends ConsumerWidget {
  final ScreenGroupModel group;
  const _GroupTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = group.playlist?.items.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mevcut yayın özeti
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.line.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.kraft.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.broadcast_on_personal_outlined,
                      color: AppColors.kraft, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        count != null
                            ? 'Aktif yayın: $count içerik'
                            : 'Henüz yayın yok',
                        style: TextStyle(
                          color: count != null
                              ? AppColors.success
                              : AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Aktif mod badge
          if (group.publishSource != null) ...[
            const SizedBox(height: 10),
            _ActiveModeBadge(source: group.publishSource!),
          ],
          // Aktif playlist içerikleri
          if (group.playlist != null && group.playlist!.items.isNotEmpty) ...[
            const SizedBox(height: 16),
            _PlaylistItemsList(items: group.playlist!.items),
          ],
          const SizedBox(height: 20),
          // Yayını durdur / devam ettir butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => ref
                  .read(screenRepositoryProvider)
                  .setGroupPaused(group.id, !group.paused),
              icon: Icon(
                group.paused
                    ? Icons.play_arrow_outlined
                    : Icons.stop_circle_outlined,
                color: group.paused ? AppColors.success : AppColors.danger,
              ),
              label: Text(
                group.paused ? 'Yayını Devam Ettir' : 'Yayını Durdur',
                style: TextStyle(
                    color: group.paused
                        ? AppColors.success
                        : AppColors.danger),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paper2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                side: BorderSide(
                    color: group.paused
                        ? AppColors.success
                        : AppColors.danger,
                    width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Playlist editörüne git butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                final playlist = group.playlist;
                if (playlist != null && playlist.items.isNotEmpty) {
                  ref
                      .read(groupEditorProvider(group.id).notifier)
                      .loadFromPlaylist(playlist);
                } else {
                  ref.read(groupEditorProvider(group.id).notifier).clear();
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScreenPlaylistScreen(group: group),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
              label: Text(
                (group.playlist == null || group.playlist!.items.isEmpty)
                    ? 'Playlist Oluştur'
                    : 'Playlist Düzenle (${group.playlist!.items.length} içerik)',
                style: const TextStyle(color: AppColors.ink),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kraft,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Aktif Mod Badge ──────────────────────────────────────────────────────────

class _ActiveModeBadge extends StatelessWidget {
  final String source;
  const _ActiveModeBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final isPlaylist = source == 'playlist';
    final color = isPlaylist ? AppColors.kraft : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPlaylist ? Icons.playlist_play : Icons.tv,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isPlaylist ? 'Playlist yayını aktif' : 'Ekran bazlı yayın aktif',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cihazlar Paneli ──────────────────────────────────────────────────────────

class _DevicesPanel extends ConsumerWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  const _DevicesPanel({required this.isOpen, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.devices_outlined,
                    color: AppColors.ink2, size: 20),
                const SizedBox(width: 10),
                const Text('Kayıtlı Cihazlar',
                    style: TextStyle(
                        color: AppColors.ink2,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(
                    isOpen
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: AppColors.muted),
              ],
            ),
          ),
        ),
        if (isOpen) const _DevicesList(),
      ],
    );
  }
}

class _DevicesList extends ConsumerWidget {
  const _DevicesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screensAsync = ref.watch(allScreensProvider);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: screensAsync.when(
        loading: () => const Center(
            child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppColors.kraft),
        )),
        error: (e, _) => Center(child: Text('$e')),
        data: (screens) {
          if (screens.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Henüz kayıtlı cihaz yok.\nTV\'lerde uygulama açık olmalı.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            padding:
                const EdgeInsets.fromLTRB(12, 4, 12, 12),
            itemCount: screens.length,
            itemBuilder: (_, i) => _DeviceTile(screen: screens[i]),
          );
        },
      ),
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  final ScreenModel screen;
  const _DeviceTile({required this.screen});

  static const _groupOptions = [
    (id: 'ekran_1', label: 'Ekran 1'),
    (id: 'ekran_2', label: 'Ekran 2'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupLabel = switch (screen.groupId) {
      'ekran_1' => 'Ekran 1',
      'ekran_2' => 'Ekran 2',
      _ => 'Atanmadı',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: screen.isOnline
                  ? AppColors.success
                  : AppColors.muted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(screen.name,
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(screen.lastSeenLabel,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          // Grup seçici
          DropdownButton<String?>(
            value: screen.groupId,
            underline: const SizedBox(),
            style: const TextStyle(
                color: AppColors.kraft, fontSize: 13),
            items: [
              const DropdownMenuItem(
                  value: null,
                  child: Text('Atanmadı',
                      style: TextStyle(color: AppColors.muted))),
              ..._groupOptions.map((g) => DropdownMenuItem(
                    value: g.id,
                    child: Text(g.label),
                  )),
            ],
            onChanged: (groupId) => ref
                .read(screenRepositoryProvider)
                .assignToGroup(screen.deviceId, groupId),
          ),
          // Sil butonu
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.danger, size: 18),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.paper2,
        title: const Text('Cihazı Kaldır',
            style: TextStyle(color: AppColors.ink)),
        content: Text('"${screen.name}" kayıtları silinsin mi?',
            style: const TextStyle(color: AppColors.ink2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal',
                  style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Kaldır',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(screenRepositoryProvider)
          .delete(screen.deviceId);
    }
  }
}

// ─── Playlist İçerik Listesi ──────────────────────────────────────────────────

class _PlaylistItemsList extends ConsumerWidget {
  final List<PlaylistItem> items;
  const _PlaylistItemsList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleMapAsync = ref.watch(contentTitleMapProvider);
    final titleMap = titleMapAsync.value ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktif İçerikler',
          style: TextStyle(
              color: AppColors.ink2,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          final contentId = item.contentRef.split('/').last;
          final title = titleMap[contentId] ?? contentId;
          return InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (_) => _ContentPreviewDialog(contentId: contentId),
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.kraft.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                          color: AppColors.kraft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(_typeIcon(item.type), color: AppColors.ink2, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          color: AppColors.ink, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    item.type == ContentType.video
                        ? 'video'
                        : '${item.durationSeconds}s',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.open_in_full,
                      color: AppColors.muted, size: 13),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  IconData _typeIcon(ContentType type) => switch (type) {
        ContentType.video => Icons.videocam_outlined,
        ContentType.image => Icons.image_outlined,
        ContentType.menu => Icons.restaurant_menu_outlined,
        ContentType.priceList => Icons.price_change_outlined,
      };
}

// ─── Content Preview Dialog ───────────────────────────────────────────────────

class _ContentPreviewDialog extends ConsumerWidget {
  final String contentId;
  const _ContentPreviewDialog({required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(_contentByIdProvider(contentId));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: contentAsync.when(
            loading: () => const ColoredBox(
              color: AppColors.paper2,
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.kraft)),
            ),
            error: (e, _) => ColoredBox(
              color: AppColors.paper2,
              child: Center(
                  child: Text('$e',
                      style:
                          const TextStyle(color: AppColors.danger))),
            ),
            data: (content) {
              if (content == null) {
                return const ColoredBox(
                  color: AppColors.paper2,
                  child: Center(
                      child: Text('İçerik bulunamadı',
                          style: TextStyle(color: AppColors.muted))),
                );
              }
              return _PreviewBody(content: content);
            },
          ),
        ),
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  final ContentItemModel content;
  const _PreviewBody({required this.content});

  @override
  Widget build(BuildContext context) {
    return switch (content) {
      ImageItemModel img => _ImagePreview(item: img),
      VideoItemModel vid => _VideoPreview(item: vid),
      MenuItemModel menu => _MenuPreview(item: menu),
      PriceListModel pl => _PriceListPreview(item: pl),
    };
  }
}

// ── Image ────────────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final ImageItemModel item;
  const _ImagePreview({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(item.downloadUrl, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image,
                    color: AppColors.muted, size: 64))),
        Positioned(
          top: 8,
          right: 8,
          child: _CloseButton(),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _TitleBar(title: item.title),
        ),
      ],
    );
  }
}

// ── Video ────────────────────────────────────────────────────────────────────

class _VideoPreview extends StatelessWidget {
  final VideoItemModel item;
  const _VideoPreview({required this.item});

  /// Cloudinary video URL'sinden ilk kare JPEG thumbnail türetir.
  /// /upload/ → /upload/so_0,w_800/ ve uzantıyı .jpg yapar.
  String _firstFrameUrl(String downloadUrl) {
    return downloadUrl
        .replaceFirst('/upload/', '/upload/so_2,w_800/')
        .replaceAll(RegExp(r'\.\w+$'), '.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final duration =
        '${(item.durationSeconds ~/ 60).toString().padLeft(2, '0')}:${(item.durationSeconds % 60).toString().padLeft(2, '0')}';
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _firstFrameUrl(item.downloadUrl),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Icon(Icons.videocam_off_outlined,
                  color: Colors.white38, size: 64),
            ),
          ),
        ),
        Positioned(top: 8, right: 8, child: _CloseButton()),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _TitleBar(title: item.title, subtitle: duration),
        ),
      ],
    );
  }
}

// ── Menu ─────────────────────────────────────────────────────────────────────

class _MenuPreview extends StatelessWidget {
  final MenuItemModel item;
  const _MenuPreview({required this.item});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF1A1A2E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseColor(item.backgroundColor);
    final accent = _parseColor(item.accentColor);
    return Stack(
      children: [
        ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(item.title,
                    style: TextStyle(
                        color: accent,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final cat in item.categories) ...[
                      Text(cat.name,
                          style: TextStyle(
                              color: accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      for (final entry in cat.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    if (entry.description.isNotEmpty)
                                      Text(entry.description,
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text(entry.price,
                                  style: TextStyle(
                                      color: accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(top: 8, right: 8, child: _CloseButton()),
      ],
    );
  }
}

// ── Price List ────────────────────────────────────────────────────────────────

class _PriceListPreview extends StatelessWidget {
  final PriceListModel item;
  const _PriceListPreview({required this.item});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF0F3460);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseColor(item.backgroundColor);
    return Stack(
      children: [
        ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(item.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: item.entries
                      .map((e) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: e.isHighlighted
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(e.name,
                                      style: TextStyle(
                                          color: e.isHighlighted
                                              ? Colors.amber
                                              : Colors.white,
                                          fontSize: 13,
                                          fontWeight: e.isHighlighted
                                              ? FontWeight.w700
                                              : FontWeight.w400)),
                                ),
                                Text(
                                  e.unit.isNotEmpty
                                      ? '${e.price} / ${e.unit}'
                                      : e.price,
                                  style: TextStyle(
                                      color: e.isHighlighted
                                          ? Colors.amber
                                          : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        Positioned(top: 8, right: 8, child: _CloseButton()),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            const Icon(Icons.close, color: Colors.white70, size: 18),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _TitleBar({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.black54,
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}
