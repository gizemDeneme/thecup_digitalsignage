import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_user_model.dart';
import '../../../data/models/audit_log_model.dart';
import '../../providers/admin_user_provider.dart';
import '../../providers/audit_provider.dart';
import '../../providers/auth_provider.dart';
import '../audit/audit_logs_screen.dart';
import '../content/content_library_screen.dart';
import '../playlist/playlist_editor_screen.dart';
import '../screens/screens_list_screen.dart';
import '../users/users_screen.dart';

/// Tab tanımı.
class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  final bool superAdminOnly;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.superAdminOnly = false,
  });
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  static const _items = [
    _NavItem(
      icon: Icons.collections_bookmark_outlined,
      label: 'içerikler',
      screen: ContentLibraryScreen(),
    ),
    _NavItem(
      icon: Icons.playlist_play_outlined,
      label: 'playlist',
      screen: PlaylistEditorScreen(),
    ),
    _NavItem(
      icon: Icons.tv_outlined,
      label: 'ekranlar',
      screen: ScreensListScreen(),
    ),
    _NavItem(
      icon: Icons.people_outline,
      label: 'kullanıcılar',
      screen: UsersScreen(),
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      label: 'audit',
      screen: AuditLogsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final currentAdminAsync = ref.watch(currentAdminProvider);
    final isSuperAdmin = currentAdminAsync.value?.role == AdminRole.superAdmin;

    final visibleItems = _items
        .where((i) => !i.superAdminOnly || isSuperAdmin)
        .toList(growable: false);

    final safeIndex =
        _selectedIndex.clamp(0, visibleItems.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('thecup admin'),
        actions: [
          IconButton(
            tooltip: 'çıkış',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              ref.read(auditServiceProvider).log(AuditAction.signOut);
              await ref.read(authServiceProvider).signOut();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isMobile
          ? visibleItems[safeIndex].screen
          : Row(
              children: [
                _SideNav(
                  items: visibleItems,
                  selectedIndex: safeIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: visibleItems[safeIndex].screen),
              ],
            ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: safeIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              items: visibleItems
                  .map((it) => BottomNavigationBarItem(
                        icon: Icon(it.icon),
                        label: it.label,
                      ))
                  .toList(),
            )
          : null,
    );
  }
}

class _SideNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SideNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.paper,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            _SideNavTile(
              item: items[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _SideNavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SideNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: selected ? AppColors.paper : AppColors.ink2,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: selected ? AppColors.paper : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
