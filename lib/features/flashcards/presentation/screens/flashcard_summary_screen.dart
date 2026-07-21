import 'package:flutter/material.dart';

import 'package:prm_frontend/features/flashcards/data/models/flashcard_model.dart';
import 'package:prm_frontend/features/flashcards/data/models/review_result_model.dart';
import 'package:prm_frontend/features/flashcards/presentation/screens/flashcard_session_screen.dart';

// FR-10: man ket thuc phien - so da thuoc/chua thuoc, XP nhan duoc, phan bo hop moi
class FlashcardSummaryScreen extends StatelessWidget {
  final ReviewSubmitResultModel result;
  final int knownCount;
  final int unknownCount;
  final FlashcardSource source;
  final String? lessonId;

  const FlashcardSummaryScreen({
    super.key,
    required this.result,
    required this.knownCount,
    required this.unknownCount,
    required this.source,
    this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Map<int, int> boxDistribution = <int, int>{};
    for (final update in result.updated) {
      boxDistribution[update.box] = (boxDistribution[update.box] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả phiên ôn'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.celebration_rounded, size: 84, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              'Hoàn thành phiên ôn!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                    label: 'Đã thuộc',
                    value: '$knownCount',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.cancel_rounded,
                    color: Colors.orange,
                    label: 'Chưa thuộc',
                    value: '$unknownCount',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.diamond_rounded,
                    color: Colors.blue,
                    label: 'XP nhận được',
                    value: '+${result.earnedXp}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.speed_rounded,
                    color: theme.colorScheme.primary,
                    label: 'XP còn lại hôm nay',
                    value: '${result.dailyXpRemaining}',
                  ),
                ),
              ],
            ),
            if (boxDistribution.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Phân bố hộp mới', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int box = 1; box <= 5; box++)
                    if ((boxDistribution[box] ?? 0) > 0) Chip(label: Text('Hộp $box: ${boxDistribution[box]} từ')),
                ],
              ),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (context) => FlashcardSessionScreen(source: source, lessonId: lessonId),
                  ),
                );
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Ôn tiếp bộ khác'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // Ve trang chinh: bo qua man home flashcards + man session/summary da push
                final navigator = Navigator.of(context);
                navigator.pop();
                if (navigator.canPop()) {
                  navigator.pop();
                }
              },
              child: const Text('Về trang chính'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
