import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/screens/profile_screen.dart';
import '../../hearts/presentation/widgets/heart_indicator.dart';
import '../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../lessons/presentation/screens/course_path_screen.dart';
import '../../practice/presentation/screens/practice_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Learn';
      case 1:
        return 'Practice';
      case 2:
        return 'Leaderboard';
      case 3:
        return 'Profile';
      default:
        return 'PRM Learning';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: Text(_getAppBarTitle()),
              centerTitle: true,
              actions: const <Widget>[HeartIndicator(), SizedBox(width: 8)],
            ),
      body: Builder(
        builder: (context) {
          switch (_currentIndex) {
            case 0:
              return const CoursePathScreen();
            case 1:
              return const PracticeScreen();
            case 2:
              return const LeaderboardScreen();
            case 3:
              return const ProfileScreen();
            default:
              return const SizedBox.shrink();
          }
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
