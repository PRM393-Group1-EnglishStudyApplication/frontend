import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The main app frame: hosts the feature tabs and the bottom navigation bar.
///
/// Receives the [StatefulNavigationShell] from go_router's
/// [StatefulShellRoute], so each tab keeps its own navigation stack and state
/// (e.g. the chat conversation survives switching tabs).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab again returns it to its initial route.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 66,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: const Color(0xFFEAF8F3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded, color: Color(0xFF07976A)),
            label: 'Học',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF07976A),
            ),
            label: 'Từ vựng',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF07976A),
            ),
            label: 'Lingua',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(
              Icons.leaderboard_rounded,
              color: Color(0xFF07976A),
            ),
            label: 'Xếp hạng',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF07976A)),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
