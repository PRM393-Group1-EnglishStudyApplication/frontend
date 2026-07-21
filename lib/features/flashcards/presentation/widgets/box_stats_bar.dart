import 'package:flutter/material.dart';

// FR-5: thong ke 5 hop (bar nho moi hop bao nhieu tu)
class BoxStatsBar extends StatelessWidget {
  final Map<String, int> boxCounts;

  const BoxStatsBar({super.key, required this.boxCounts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<int> counts = List<int>.generate(5, (i) => boxCounts['${i + 1}'] ?? 0);
    final int maxCount = counts.fold<int>(1, (a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List<Widget>.generate(5, (i) {
        final int count = counts[i];
        final double heightFactor = count / maxCount;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10 + 46 * heightFactor,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25 + 0.12 * i),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Hộp ${i + 1}', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        );
      }),
    );
  }
}
