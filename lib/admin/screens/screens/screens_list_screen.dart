import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/screen_model.dart';
import '../../../data/models/screen_group_model.dart';
import '../../providers/screen_provider.dart';
import 'screen_playlist_screen.dart';

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
    final items = ref.watch(groupEditorProvider(group.id));
    final count = group.playlist?.items.length;

    return Padding(
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
          const SizedBox(height: 20),
          // Playlist editörüne git butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScreenPlaylistScreen(group: group),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
              label: Text(
                items.isEmpty
                    ? 'Playlist Oluştur'
                    : 'Playlist Düzenle (${items.length} içerik)',
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
