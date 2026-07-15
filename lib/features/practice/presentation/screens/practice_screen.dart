import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../hearts/presentation/providers/heart_providers.dart';
import '../providers/practice_providers.dart';
import 'practice_pack_screen.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final streakAsync = ref.watch(practiceStreakProvider);
    final completedAsync = ref.watch(completedLessonCountProvider);
    final earnedXpAsync = ref.watch(earnedXpProvider);
    final accuracyAsync = ref.watch(accuracyPercentageProvider);

    final String fullName = userAsync.maybeWhen(
      data: (user) => user.fullName ?? 'Hoc vien',
      orElse: () => 'PRM Student',
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(completedLessonCountProvider);
          ref.invalidate(earnedXpProvider);
          ref.invalidate(accuracyPercentageProvider);
          await ref.read(currentUserProvider.notifier).loadUser();
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Chao, $fullName!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thong tin luyen tap duoc dong bo tu backend.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.auto_stories_rounded,
                  color: theme.colorScheme.primary,
                  size: 36,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Consumer(
              builder: (context, ref, child) {
                final heartState = ref.watch(heartProvider);
                final currentHearts = heartState.hearts?.currentHearts ?? 0;
                final bool hasHearts = currentHearts > 0;

                return Card(
                  elevation: 4,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fitness_center_rounded,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Luyện Tập Ngẫu Nhiên',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '10 câu hỏi đa dạng độ khó từ ngân hàng đề.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!hasHearts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: theme.colorScheme.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Hết tim! Hãy hồi phục tim trước khi luyện tập.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        FilledButton.icon(
                          onPressed: hasHearts
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) => const PracticePackScreen(),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Bắt đầu luyện tập'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Practice insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MetricCard(
                    icon: Icons.local_fire_department_rounded,
                    color: Colors.deepOrange,
                    label: 'Streak',
                    value: streakAsync.when(
                      data: (value) => '$value ngay',
                      loading: () => '--',
                      error: (_, __) => '--',
                    ),
                    helper: 'Tu ho so backend',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                    label: 'Bai hoan thanh',
                    value: completedAsync.when(
                      data: (value) => '$value',
                      loading: () => '--',
                      error: (_, __) => '--',
                    ),
                    helper: 'Tu /api/progress/me',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MetricCard(
                    icon: Icons.diamond_rounded,
                    color: Colors.blue,
                    label: 'XP bai hoc',
                    value: earnedXpAsync.when(
                      data: (value) => '$value',
                      loading: () => '--',
                      error: (_, __) => '--',
                    ),
                    helper: 'Tong XP progress',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.gps_fixed_rounded,
                    color: Colors.teal,
                    label: 'Do chinh xac',
                    value: accuracyAsync.when(
                      data: (value) => value == 0 ? '--' : '$value%',
                      loading: () => '--',
                      error: (_, __) => '--',
                    ),
                    helper: 'Diem trung binh',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Can xem lai',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _UnavailableWrongAnswersCard(
              onRefresh: () => ref.invalidate(completedLessonCountProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String helper;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              helper,
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

class _UnavailableWrongAnswersCard extends StatelessWidget {
  final VoidCallback onRefresh;

  const _UnavailableWrongAnswersCard({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Chua co du lieu cau sai',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Khi ban hoan thanh them bai hoc, nhung cau can on lai se duoc hien thi tai day.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tai lai'),
            ),
          ],
        ),
      ),
    );
  }
}
