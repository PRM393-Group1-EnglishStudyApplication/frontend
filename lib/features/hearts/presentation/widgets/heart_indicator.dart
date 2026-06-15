import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/heart_providers.dart';

class HeartIndicator extends ConsumerWidget {
  const HeartIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HeartState state = ref.watch(heartProvider);
    final int? count = state.hearts?.currentHearts;

    return Semantics(
      button: true,
      label: count == null ? 'Hearts loading' : '$count hearts remaining',
      child: TextButton.icon(
        key: const Key('heart_indicator_button'),
        onPressed: () => _showHeartSheet(context),
        style: TextButton.styleFrom(
          foregroundColor: state.isOutOfHearts
              ? Colors.grey.shade600
              : const Color(0xFFE94057),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(48, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: state.isLoading && count == null
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                state.isOutOfHearts
                    ? Icons.favorite_border_rounded
                    : Icons.favorite_rounded,
              ),
        label: Text(
          count?.toString() ?? '--',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }

  void _showHeartSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => const HeartDetailsSheet(),
    );
  }
}

class HeartDetailsSheet extends ConsumerWidget {
  const HeartDetailsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final HeartState state = ref.watch(heartProvider);
    final int current = state.hearts?.currentHearts ?? 0;
    final int maximum = state.hearts?.maxHearts ?? 5;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFE94057),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.isOutOfHearts ? 'You are out of hearts' : 'Your hearts',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.isOutOfHearts
                  ? 'Lessons are paused until your hearts are refilled.'
                  : 'A wrong answer costs one heart. Keep learning carefully!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: List<Widget>.generate(maximum, (int index) {
                final bool filled = index < current;
                return Icon(
                  filled
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: filled
                      ? const Color(0xFFE94057)
                      : theme.colorScheme.outline,
                  size: 34,
                );
              }),
            ),
            const SizedBox(height: 18),
            if (state.refillRemaining != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.timer_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Full refill in',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _formatDuration(state.refillRemaining!),
                            key: const Key('heart_refill_countdown'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (state.errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('refill_hearts_button'),
                onPressed: state.isRefilling
                    ? null
                    : () => ref.read(heartProvider.notifier).refillHearts(),
                icon: state.isRefilling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.favorite_rounded),
                label: Text(
                  state.isRefilling ? 'Refilling...' : 'Refill hearts now',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
