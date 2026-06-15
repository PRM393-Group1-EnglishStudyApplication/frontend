import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/entities/app_user.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../auth/presentation/screens/profile_screen.dart';
import '../../hearts/presentation/providers/heart_providers.dart';
import '../../hearts/presentation/widgets/heart_indicator.dart';
import '../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../lessons/data/models/course_model.dart';
import '../../lessons/presentation/providers/lessons_providers.dart';
import '../../lessons/presentation/screens/course_detail_screen.dart';
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
        return 'Học';
      case 1:
        return 'Luyện tập';
      case 2:
        return 'Bảng xếp hạng';
      case 3:
        return 'Hồ sơ';
      default:
        return 'PRM Learning';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        actions: const <Widget>[HeartIndicator(), SizedBox(width: 8)],
      ),
      body: Builder(
        builder: (context) {
          switch (_currentIndex) {
            case 0:
              return _buildCoursesTab(context);
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
            label: 'Học',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Luyện tập',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Xếp hạng',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    final theme = Theme.of(context);
    final clerkUser = ClerkAuth.of(context).user;
    final String fullName =
        (clerkUser?.name != null && clerkUser!.name.isNotEmpty)
        ? clerkUser.name
        : 'PRM Student';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting Card
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fullName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "You're making great progress! Ready to learn something new today?",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Quick Learning Summary
          Text(
            'Quick Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer(
                builder: (context, ref, child) {
                  final userAsync = ref.watch(currentUserProvider);
                  return userAsync.when(
                    data: (user) => Column(
                      children: [
                        _buildSummaryRow(
                          context,
                          icon: Icons.star_rounded,
                          color: Colors.amber,
                          title: 'Current Level',
                          value: user.currentLevel.toUpperCase(),
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          context,
                          icon: Icons.local_fire_department_rounded,
                          color: Colors.deepOrange,
                          title: 'Streak',
                          value: '${user.streakCount} Days',
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          context,
                          icon: Icons.emoji_events_rounded,
                          color: Colors.orange,
                          title: 'Total XP',
                          value: '${user.totalXp} XP',
                        ),
                      ],
                    ),
                    loading: () => Column(
                      children: [
                        _buildSummaryRowLoading(
                          context,
                          icon: Icons.star_rounded,
                          color: Colors.amber,
                          title: 'Current Level',
                        ),
                        const Divider(height: 24),
                        _buildSummaryRowLoading(
                          context,
                          icon: Icons.local_fire_department_rounded,
                          color: Colors.deepOrange,
                          title: 'Streak',
                        ),
                        const Divider(height: 24),
                        _buildSummaryRowLoading(
                          context,
                          icon: Icons.emoji_events_rounded,
                          color: Colors.orange,
                          title: 'Total XP',
                        ),
                      ],
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sync_problem_rounded,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Failed to sync stats: $error',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: () => ref
                                .read(currentUserProvider.notifier)
                                .loadUser(),
                            child: const Text('Retry Sync'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRowLoading(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }

  Widget _buildCoursesTab(BuildContext context) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(coursesDataProvider);

    return coursesAsync.when(
      data: (courses) {
        return ListView.separated(
          padding: const EdgeInsets.all(24.0),
          itemCount: courses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final course = courses[index];
            IconData courseIcon = Icons.menu_book_rounded;
            if (course.title.toLowerCase().contains('english')) {
              courseIcon = Icons.language_rounded;
            } else if (course.title.toLowerCase().contains('conversation')) {
              courseIcon = Icons.chat_bubble_outline_rounded;
            } else if (course.title.toLowerCase().contains('toeic')) {
              courseIcon = Icons.assignment_rounded;
            } else if (course.title.toLowerCase().contains('business')) {
              courseIcon = Icons.business_center_rounded;
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    courseIcon,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  course.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    course.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  final HeartState heartState = ref.read(heartProvider);
                  if (!heartState.canStartLesson) {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          icon: const Icon(
                            Icons.heart_broken_rounded,
                            color: Color(0xFFE94057),
                            size: 36,
                          ),
                          title: const Text('Hết lượt tim'),
                          content: const Text(
                            'Hãy nạp lại tim trước khi bắt đầu bài học mới.',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Đóng'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                ref.read(heartProvider.notifier).refillHearts();
                              },
                              child: const Text('Nạp tim'),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => CourseDetailScreen(course: course),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync_problem_rounded, color: theme.colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải khóa học: $err',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(coursesDataProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCourse(String title) {
    final HeartState heartState = ref.read(heartProvider);
    if (!heartState.canStartLesson) {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const Icon(
              Icons.heart_broken_rounded,
              color: Color(0xFFE94057),
              size: 36,
            ),
            title: const Text('No hearts left'),
            content: const Text(
              'Refill your hearts before starting another lesson.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(heartProvider.notifier).refillHearts();
                },
                child: const Text('Refill hearts'),
              ),
            ],
          );
        },
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Selected: $title')));
  }

  Widget _buildProgressTab(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Stats Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final userAsync = ref.watch(currentUserProvider);
              return userAsync.when(
                data: (user) => _buildStatsGrid(context, user),
                loading: () => _buildStatsGridLoading(context),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sync_problem_rounded,
                          color: theme.colorScheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to sync statistics: $error',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () =>
                              ref.read(currentUserProvider.notifier).loadUser(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppUser user) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: <Widget>[
        _buildStatCard(
          context,
          icon: Icons.star_rounded,
          color: Colors.amber,
          label: 'Total XP',
          value: '${user.totalXp} XP',
        ),
        _buildStatCard(
          context,
          icon: Icons.emoji_events_rounded,
          color: Colors.orange,
          label: 'Level',
          value: user.currentLevel.toUpperCase(),
        ),
        _buildStatCard(
          context,
          icon: Icons.local_fire_department_rounded,
          color: Colors.deepOrange,
          label: 'Streak',
          value: '${user.streakCount} Days',
        ),
        _buildStatCard(
          context,
          icon: Icons.verified_user_rounded,
          color: Colors.blue,
          label: 'Status',
          value: 'Active',
        ),
      ],
    );
  }

  Widget _buildStatsGridLoading(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: <Widget>[
        _buildStatCardLoading(
          context,
          icon: Icons.star_rounded,
          color: Colors.amber,
          label: 'Total XP',
        ),
        _buildStatCardLoading(
          context,
          icon: Icons.emoji_events_rounded,
          color: Colors.orange,
          label: 'Level',
        ),
        _buildStatCardLoading(
          context,
          icon: Icons.local_fire_department_rounded,
          color: Colors.deepOrange,
          label: 'Streak',
        ),
        _buildStatCardLoading(
          context,
          icon: Icons.verified_user_rounded,
          color: Colors.blue,
          label: 'Status',
        ),
      ],
    );
  }

  Widget _buildStatCardLoading(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(icon, color: color, size: 28),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    final theme = Theme.of(context);
    final clerkUser = ClerkAuth.of(context).user;
    final String fullName =
        (clerkUser?.name != null && clerkUser!.name.isNotEmpty)
        ? clerkUser.name
        : 'PRM Student';
    final String email = clerkUser?.email ?? '';
    final String? avatarUrl = clerkUser?.imageUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: <Widget>[
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(
                            (fullName.isNotEmpty ? fullName : email)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Full Name
                  Text(
                    fullName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, child) {
              final userAsync = ref.watch(currentUserProvider);
              return userAsync.when(
                data: (_) => const SizedBox.shrink(),
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Syncing stats with backend...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sync failed: $error',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Action Buttons
          FilledButton.icon(
            onPressed: () {
              ref.read(currentUserProvider.notifier).loadUser();
            },
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Sync with Backend'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await ClerkAuth.of(context).signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to sign out: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(icon, color: color, size: 28),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
