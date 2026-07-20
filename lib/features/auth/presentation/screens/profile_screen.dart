import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../achievements/presentation/providers/achievements_providers.dart';
import '../../../achievements/presentation/screens/achievements_screen.dart';
import '../../../admin/presentation/screens/admin_main_screen.dart';
import '../../../leaderboard/presentation/providers/leaderboard_providers.dart';
import '../../../notifications/presentation/screens/reminder_settings_screen.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../../progress/presentation/screens/progress_screen.dart';
import '../providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final achievementsAsync = ref.watch(combinedAchievementsProvider);
    final myRankAsync = ref.watch(myLeaderboardProvider);
    final progressAsync = ref.watch(progressSummaryProvider);

    return Scaffold(
      body: userAsync.when(
        data: (user) {
          final String fullName = user.fullName ?? 'Hoc vien';
          final String? avatarUrl = user.avatarUrl;

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(currentUserProvider.notifier).loadUser();
              ref.invalidate(myLeaderboardProvider);
              ref.invalidate(combinedAchievementsProvider);
              ref.invalidate(progressSummaryProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: theme.colorScheme.primary,
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  fullName.isNotEmpty
                                      ? fullName.substring(0, 1).toUpperCase()
                                      : 'U',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fullName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.deepOrange,
                        label: 'Streak',
                        value: '${user.streakCount}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.diamond_rounded,
                        color: Colors.blue,
                        label: 'Total XP',
                        value: '${user.totalXp}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: myRankAsync.when(
                        data: (entry) => _StatCard(
                          icon: Icons.emoji_events_rounded,
                          color: Colors.amber.shade700,
                          label: 'Weekly rank',
                          value: entry.rankPosition > 0
                              ? '#${entry.rankPosition}'
                              : 'Unranked',
                        ),
                        loading: () => _StatCard(
                          icon: Icons.emoji_events_rounded,
                          color: Colors.amber.shade700,
                          label: 'Weekly rank',
                          value: '--',
                        ),
                        error: (_, __) => _StatCard(
                          icon: Icons.emoji_events_rounded,
                          color: Colors.amber.shade700,
                          label: 'Weekly rank',
                          value: 'Error',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.insights_rounded),
                    title: const Text('Learning progress'),
                    subtitle: progressAsync.when(
                      data: (summary) => Text(
                        '${summary.completedLessons} completed lessons - ${summary.averageScore == 0 ? '--' : '${summary.averageScore}%'} average score',
                      ),
                      loading: () => const Text('Loading progress...'),
                      error: (_, __) => const Text('Unable to sync progress'),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const ProgressScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_rounded),
                    title: const Text('Nhắc nhở học tập'),
                    subtitle: const Text('Đặt giờ nhắc hằng ngày để giữ streak'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const ReminderSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Achievements',
                  actionLabel: 'View all',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const AchievementsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                achievementsAsync.when(
                  data: (achievements) {
                    final unlocked =
                        achievements.where((item) => item.isUnlocked).take(2).toList();
                    if (unlocked.isEmpty) {
                      return Text(
                        'Complete lessons to unlock your first achievement.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }

                    return Row(
                      children: unlocked
                          .map(
                            (achievement) => Expanded(
                              child: Card(
                                elevation: 0,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: <Widget>[
                                      Icon(
                                        _achievementIcon(achievement.iconUrl),
                                        color: _achievementColor(achievement.iconUrl),
                                        size: 30,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        achievement.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${achievement.requiredXp} XP',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Unable to load achievements'),
                ),
                if (user.isAdmin) ...[
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const AdminMainScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    label: const Text('Admin course management'),
                  ),
                ],
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
                  label: const Text('Sign out'),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.sync_problem_rounded,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to sync profile: $err',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.read(currentUserProvider.notifier).loadUser(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _achievementIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
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

  Color _achievementColor(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'local_fire_department':
        return Colors.deepOrange;
      case 'bolt':
        return Colors.amber;
      case 'diamond':
        return Colors.blue;
      case 'workspace_premium':
        return Colors.amber;
      default:
        return Colors.amber;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(127)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton.icon(
          onPressed: onPressed,
          label: Text(actionLabel),
          icon: const Icon(Icons.chevron_right_rounded, size: 16),
        ),
      ],
    );
  }
}
