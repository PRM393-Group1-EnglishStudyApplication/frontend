import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/lesson_model.dart';
import '../data/services/lesson_service.dart';
import '../../auth/presentation/providers/auth_providers.dart';

final _lessonServiceProvider = Provider<LessonService>((ref) {
  return LessonService(ref.watch(authDioProvider));
});

final _lessonsProvider = FutureProvider.family<List<LessonModel>, String>(
  (ref, unitId) => ref.watch(_lessonServiceProvider).getLessons(unitId),
);

class LessonListPage extends ConsumerWidget {
  final String unitId;

  const LessonListPage({super.key, required this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lessonsAsync = ref.watch(_lessonsProvider(unitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Lessons'), centerTitle: true),
      body: lessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No lessons available', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _LessonCard(
              lesson: lessons[i],
              isLocked: i > 0,
              index: i,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Failed to load lessons', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(_lessonsProvider(unitId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final bool isLocked;
  final int index;

  const _LessonCard({
    required this.lesson,
    required this.isLocked,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLocked
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLocked
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complete the previous lesson to unlock')),
                )
            : () => context.go('/lessons/${lesson.id}/vocabulary'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLocked
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isLocked
                      ? Icon(Icons.lock_rounded,
                          size: 20, color: theme.colorScheme.onSurfaceVariant)
                      : Text(
                          '${index + 1}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  lesson.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isLocked ? theme.colorScheme.onSurfaceVariant : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLocked
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${lesson.xpReward} XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLocked
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                color: isLocked ? theme.colorScheme.outlineVariant : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
