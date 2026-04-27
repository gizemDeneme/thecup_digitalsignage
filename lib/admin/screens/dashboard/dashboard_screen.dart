import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../content/content_library_screen.dart';
import '../playlist/playlist_editor_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    ContentLibraryScreen(),
    PlaylistEditorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213E),
          title: const Text('thecup Admin',
              style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: const Color(0xFF16213E),
          selectedItemColor: const Color(0xFFE94560),
          unselectedItemColor: Colors.white38,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library),
              label: 'İçerikler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.playlist_play),
              label: 'Playlist',
            ),
          ],
        ),
      );
    }

    // Desktop: Tab layout
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213E),
          title: const Text('thecup Admin',
              style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFFE94560),
            labelColor: Color(0xFFE94560),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.photo_library), text: 'İçerikler'),
              Tab(icon: Icon(Icons.playlist_play), text: 'Playlist'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ContentLibraryScreen(),
            PlaylistEditorScreen(),
          ],
        ),
      ),
    );
  }
}
