import 'package:flutter/material.dart';
import '../../domain/entities/achievement.dart';

class BadgeDetailSheet extends StatelessWidget {
  final Achievement achievement;

  const BadgeDetailSheet({super.key, required this.achievement});

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = achievement.isUnlocked;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Big Badge Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _getIconColor(achievement.iconUrl, unlocked).withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getIconColor(achievement.iconUrl, unlocked).withAlpha(75),
                width: 2,
              ),
            ),
            child: Icon(
              _getIconData(achievement.iconUrl),
              size: 72,
              color: _getIconColor(achievement.iconUrl, unlocked),
            ),
          ),
          const SizedBox(height: 20),

          // Badge Name
          Text(
            achievement.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: unlocked
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                  size: 16,
                  color: unlocked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  unlocked ? 'Đã mở khóa' : 'Chưa mở khóa',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: unlocked
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            achievement.description ?? 'Không có mô tả cho huy hiệu này.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Requirements Detail
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withAlpha(75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withAlpha(127),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yêu cầu để mở khóa',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tích lũy tối thiểu ${achievement.requiredXp} XP từ các bài học.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Date unlocked (if any)
          if (unlocked && achievement.unlockedAt != null)
            Text(
              'Đạt được vào ${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
