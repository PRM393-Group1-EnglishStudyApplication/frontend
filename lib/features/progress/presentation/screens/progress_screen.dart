import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(progressSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        centerTitle: true,
      ),
      body: summaryAsync.when(
        data: (summary) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(progressEntriesProvider);
            ref.invalidate(progressSummaryProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SummaryCard(
                      label: 'Completed lessons',
                      value: '${summary.completedLessons}',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Earned XP',
                      value: '${summary.totalXp}',
                      icon: Icons.diamond_rounded,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                label: 'Average score',
                value: summary.averageScore == 0 ? '--' : '${summary.averageScore}%',
                icon: Icons.gps_fixed_rounded,
                color: Colors.teal,
              ),
              const SizedBox(height: 28),
              Text(
                'Latest completed lessons',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (summary.latestCompletedLessons.isEmpty)
                _EmptyProgressCard(theme: theme)
              else
                ...summary.latestCompletedLessons.map(
                  (entry) => Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.task_alt_rounded),
                      title: Text(entry.lessonTitle),
                      subtitle: Text('Score ${entry.score}% - ${entry.earnedXp} XP'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
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
                  'Unable to load progress: $error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () {
                    ref.invalidate(progressEntriesProvider);
                    ref.invalidate(progressSummaryProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
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
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _EmptyProgressCard extends StatelessWidget {
  final ThemeData theme;

  const _EmptyProgressCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No completed lessons yet. Finish a lesson to sync progress from backend.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
