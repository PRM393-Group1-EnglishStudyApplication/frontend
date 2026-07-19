import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/deep_link.dart';
import '../../auth/presentation/screens/profile_screen.dart';
import '../../chat/presentation/providers/chat_providers.dart';
import '../../chat/presentation/screens/chat_screen.dart';
import '../../hearts/presentation/widgets/heart_indicator.dart';
import '../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../lessons/domain/entities/exercise_entities.dart';
import '../../lessons/domain/entities/lesson.dart';
import '../../lessons/presentation/providers/lessons_providers.dart';
import '../../lessons/presentation/screens/course_path_screen.dart';
import '../../lessons/presentation/screens/lesson_screen.dart';
import '../../notifications/presentation/providers/notification_providers.dart';
import '../../practice/presentation/screens/practice_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const int _chatIndex = 3;
  static const int _learnIndex = 0;

  int _currentIndex = 0;

  /// Chặn hai lần điều hướng chồng nhau khi user bấm liên tiếp hai thông báo.
  bool _handlingDeepLink = false;

  @override
  void initState() {
    super.initState();
    // Deep-link có thể đã được giữ sẵn từ lúc app khởi động (trạng thái terminated),
    // tức là trước khi HomePage tồn tại để nghe được (FR-7).
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingDeepLink());
  }

  void _consumePendingDeepLink() {
    final PendingDeepLink? link = ref.read(pendingDeepLinkProvider);
    if (link != null) {
      ref.read(pendingDeepLinkProvider.notifier).state = null;
      unawaited(_navigateTo(link));
    }
  }

  Future<void> _navigateTo(PendingDeepLink link) async {
    if (_handlingDeepLink) {
      return;
    }
    _handlingDeepLink = true;

    try {
      final int? tabIndex = link.tabIndex;
      if (tabIndex != null && mounted) {
        setState(() => _currentIndex = tabIndex);
      }

      if (link.route != DeepLinkRoute.lesson || link.lessonId == null) {
        return;
      }

      // Không tin lesson_id trong payload: phải hỏi server rồi mới mở màn hình.
      // Bài học đã bị xoá thì dừng lại ở tab Learn thay vì mở màn hình rỗng.
      try {
        final LessonDetail detail =
            await ref.read(lessonsRepositoryProvider).getLessonDetail(link.lessonId!);
        if (!mounted) {
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => LessonScreen(
              lesson: Lesson(
                id: detail.id,
                title: detail.title,
                orderIndex: detail.orderIndex,
                xpReward: detail.xpReward,
                unitId: detail.unitId,
              ),
            ),
          ),
        );
      } catch (error) {
        if (mounted) {
          setState(() => _currentIndex = _learnIndex);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không mở được bài học từ thông báo.')),
          );
        }
      }
    } finally {
      _handlingDeepLink = false;
    }
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Learn';
      case 1:
        return 'Practice';
      case 2:
        return 'Leaderboard';
      case 3:
        return 'Lingua';
      case 4:
        return 'Profile';
      default:
        return 'PRM Learning';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thông báo bấm khi app đang mở hoặc chạy nền đi vào đây.
    ref.listen<PendingDeepLink?>(pendingDeepLinkProvider, (_, PendingDeepLink? link) {
      if (link != null) {
        ref.read(pendingDeepLinkProvider.notifier).state = null;
        unawaited(_navigateTo(link));
      }
    });

    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: Text(_getAppBarTitle()),
              centerTitle: true,
              actions: <Widget>[
                if (_currentIndex == _chatIndex)
                  IconButton(
                    tooltip: 'Cuộc trò chuyện mới',
                    icon: const Icon(Icons.add_comment_outlined),
                    onPressed: () => ref.read(chatProvider.notifier).reset(),
                  ),
                const HeartIndicator(),
                const SizedBox(width: 8),
              ],
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
              return const ChatScreen();
            case 4:
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
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Lingua',
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
