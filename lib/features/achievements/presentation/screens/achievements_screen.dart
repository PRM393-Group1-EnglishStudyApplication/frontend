import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/achievement.dart';
import '../providers/achievements_providers.dart';
import '../widgets/badge_detail_sheet.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  IconData _getIconData(String? iconName) {
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
      case 'star':
        return Icons.star_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  Color _getIconColor(String? iconName, bool unlocked) {
    if (!unlocked) return Colors.grey;
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
    final achievementsAsync = ref.watch(combinedAchievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh hiệu & Thành tích'),
        centerTitle: true,
      ),
      body: achievementsAsync.when(
        data: (achievements) {
          if (achievements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.military_tech_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(127),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có thành tích nào',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final unlockedCount = achievements.where((a) => a.isUnlocked).length;

          return Column(
            children: [
              // Summary Banner
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withAlpha(127),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.military_tech_rounded,
                      color: theme.colorScheme.primary,
                      size: 48,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tiến trình mở khóa',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bạn đã mở khóa $unlockedCount trên tổng số ${achievements.length} danh hiệu.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Grid List of Badges
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    final unlocked = achievement.isUnlocked;
                    final iconColor = _getIconColor(achievement.iconUrl, unlocked);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: unlocked
                              ? iconColor.withAlpha(75)
                              : theme.colorScheme.outlineVariant.withAlpha(127),
                          width: unlocked ? 1.5 : 1,
                        ),
                      ),
                      color: unlocked
                          ? iconColor.withAlpha(7)
                          : theme.colorScheme.surface,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => BadgeDetailSheet(achievement: achievement),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: iconColor.withAlpha(25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIconData(achievement.iconUrl),
                                      size: 44,
                                      color: iconColor,
                                    ),
                                  ),
                                  if (!unlocked)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: theme.colorScheme.outlineVariant,
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.lock_rounded,
                                          size: 12,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Name
                              Text(
                                achievement.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: unlocked ? null : theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Description or Progress
                              Text(
                                unlocked ? 'Đã đạt' : 'Cần ${achievement.requiredXp} XP',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: unlocked
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
                'Lỗi tải thành tích: $err',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(combinedAchievementsProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
