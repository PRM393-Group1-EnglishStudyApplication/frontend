import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../achievements/presentation/providers/achievements_providers.dart';
import '../../../achievements/presentation/screens/achievements_screen.dart';
import '../providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  IconData _getAchievementIcon(String? iconName) {
    if (iconName == null) return Icons.military_tech_rounded;
    switch (iconName.toLowerCase()) {
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'diamond':
        return Icons.diamond_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  Color _getAchievementColor(String? iconName) {
    if (iconName == null) return Colors.amber;
    switch (iconName.toLowerCase()) {
      case 'local_fire_department':
        return Colors.deepOrange;
      case 'bolt':
        return Colors.amber;
      case 'diamond':
        return Colors.blue;
      case 'workspace_premium':
        return Colors.amber.shade700;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final achievementsAsync = ref.watch(combinedAchievementsProvider);

    return Scaffold(
      body: userAsync.when(
        data: (user) {
          final String fullName = user.fullName ?? 'Học viên';
          final String email = user.email;
          final String? avatarUrl = user.avatarUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Details Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.primaryContainer.withAlpha(75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withAlpha(25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: <Widget>[
                        // Avatar with Edit Button overlay
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: theme.colorScheme.primary,
                              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null || avatarUrl.isEmpty
                                  ? Text(
                                      fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
                                      style: theme.textTheme.headlineLarge?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.surface, width: 2),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Full Name
                        Text(
                          fullName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Joined Date or Email
                        Text(
                          'Tham gia từ Tháng 8, 2023',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Row Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.deepOrange,
                        label: 'Chuỗi ngày',
                        value: '${user.streakCount}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.diamond_rounded,
                        color: Colors.blue,
                        label: 'Tổng XP',
                        value: '${user.totalXp}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.emoji_events_rounded,
                        color: Colors.amber.shade700,
                        label: 'Giải đấu',
                        value: 'Vàng',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Achievements Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thành tích',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const AchievementsScreen(),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Text('Xem tất cả'),
                          Icon(Icons.chevron_right_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // First 2 Achievements List
                achievementsAsync.when(
                  data: (achievements) {
                    final unlocked = achievements.where((a) => a.isUnlocked).take(2).toList();
                    if (unlocked.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Hoàn thành bài học để mở khóa thành tích đầu tiên!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }
                    return Row(
                      children: unlocked.map((achievement) {
                        final color = _getAchievementColor(achievement.iconUrl);
                        return Expanded(
                          child: Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant.withAlpha(127),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    _getAchievementIcon(achievement.iconUrl),
                                    color: color,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          achievement.name,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Cấp độ ${achievement.requiredXp ~/ 100 > 0 ? achievement.requiredXp ~/ 100 : 1}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Friends Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bạn bè',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thêm bạn bè...')),
                        );
                      },
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: const Text('Thêm'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Friends List
                _buildFriendRow(context, 'Lan Anh', '2,450 XP', Colors.amber),
                _buildFriendRow(context, 'Quốc Bảo', '1,890 XP', Colors.grey),
                const SizedBox(height: 32),

                // Sign Out
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
                  label: const Text('Đăng xuất'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error.withAlpha(127)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync_problem_rounded, color: theme.colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Lỗi đồng bộ hồ sơ: $err',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.read(currentUserProvider.notifier).loadUser(),
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
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
          color: theme.colorScheme.outlineVariant.withAlpha(127),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRow(BuildContext context, String name, String xp, Color badgeColor) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(127),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.surfaceVariant,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'F',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(
            Icons.workspace_premium_rounded,
            color: badgeColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            xp,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
