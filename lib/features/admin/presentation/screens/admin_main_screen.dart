import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../leaderboard/presentation/providers/leaderboard_providers.dart';
import '../../../lessons/presentation/providers/lessons_providers.dart';
import 'curriculum_management_screen.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> tabs = [
      _buildDashboardTab(context),
      const CurriculumManagementScreen(),
      _buildUserTab(context),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex < 3 ? _selectedIndex : 0,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            // Exit Admin Mode
            Navigator.pop(context);
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_rounded),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app_rounded, color: Colors.red),
            label: 'Thoát',
          ),
        ],
      ),
    );
  }

  // === Tab 0: Admin Dashboard ===
  Widget _buildDashboardTab(BuildContext context) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(coursesDataProvider);
    final leaderboardAsync = ref.watch(leaderboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bento stats cards
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    context,
                    title: 'Tổng số khóa học',
                    value: coursesAsync.when(
                      data: (list) => '${list.length}',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.menu_book_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBentoCard(
                    context,
                    title: 'Học viên active',
                    value: leaderboardAsync.when(
                      data: (list) => '${list.length}',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.people_rounded,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    context,
                    title: 'Điểm XP tuần này',
                    value: leaderboardAsync.when(
                      data: (list) {
                        final totalXp = list.fold<int>(0, (sum, entry) => sum + entry.xp);
                        return '${totalXp} XP';
                      },
                      loading: () => '...',
                      error: (_, __) => '0 XP',
                    ),
                    icon: Icons.bolt_rounded,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBentoCard(
                    context,
                    title: 'Tỉ lệ hoạt động',
                    value: '100%',
                    icon: Icons.trending_up_rounded,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent activity or summary list
            Text(
              'Tổng quan các khóa học',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            coursesAsync.when(
              data: (courses) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.bookmark_border_rounded, color: theme.colorScheme.primary),
                        ),
                        title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Độ khó: ${course.targetLevel.toUpperCase()}'),
                        trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary),
                        onTap: () {
                          // Switch to tab 1 (Courses) and let the builder show it
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (err, _) => Text('Lỗi tải danh sách: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === Tab 2: User List (Student management) ===
  Widget _buildUserTab(BuildContext context) {
    final theme = Theme.of(context);
    final leaderboardAsync = ref.watch(leaderboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách học viên', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: leaderboardAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text(
                'Không tìm thấy dữ liệu học viên.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final user = entry.user;

              final fullName = user?.fullName ?? 'Học viên';
              final email = user?.email ?? 'Không có email';
              final avatarUrl = user?.avatarUrl;
              final streak = user?.streakCount ?? 0;
              final totalXp = user?.totalXp ?? 0;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(
                                fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Student detail info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Badges row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        '$streak ngày',
                                        style: const TextStyle(
                                          color: Colors.deepOrange,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Level: ${user?.currentLevel.toUpperCase() ?? 'BEGINNER'}',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // XP values
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.xp} XP',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Tổng: $totalXp XP',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Lỗi khi tải danh sách: $err'),
        ),
      ),
    );
  }
}
