import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../hearts/presentation/providers/heart_providers.dart';

enum OutOfHeartsNoticeAction { refilled, exited }

Future<OutOfHeartsNoticeAction?> showOutOfHeartsNoticeSheet(
  BuildContext context,
) {
  return showModalBottomSheet<OutOfHeartsNoticeAction>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const _OutOfHeartsNoticeSheet(),
  );
}

class _OutOfHeartsNoticeSheet extends ConsumerWidget {
  const _OutOfHeartsNoticeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final HeartState heartState = ref.watch(heartProvider);
    final int currentHearts = heartState.hearts?.currentHearts ?? 0;
    final int maxHearts = heartState.hearts?.maxHearts ?? 5;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFFFEFF1), Color(0xFFFFFFFF)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: const Color(0xFFFFD7DC)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDCE1),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x33E94057),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.heart_broken_rounded,
                      size: 48,
                      color: Color(0xFFE94057),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ban da het tim',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB4233A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ban vua tra loi sai va khong con du tim de tiep tuc bai hoc nay.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFE3E8)),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFE94057),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Tim hien tai: $currentHearts / $maxHearts',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.timer_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              heartState.refillRemaining == null
                                  ? 'Dang dong bo thoi gian hoi tim...'
                                  : 'Hoi tim sau: ${_formatDuration(heartState.refillRemaining!)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: heartState.isRefilling
                      ? null
                      : () async {
                          await ref.read(heartProvider.notifier).refillHearts();
                          if (!context.mounted) {
                            return;
                          }
                          final HeartState updated = ref.read(heartProvider);
                          if (!updated.isOutOfHearts) {
                            Navigator.of(
                              context,
                            ).pop(OutOfHeartsNoticeAction.refilled);
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Chua the nap tim luc nay. Vui long thu lai sau.',
                              ),
                            ),
                          );
                        },
                  icon: heartState.isRefilling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.favorite_rounded),
                  label: Text(
                    heartState.isRefilling
                        ? 'Dang nap tim...'
                        : 'Nap tim de tiep tuc',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: const Color(0xFFE94057),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(OutOfHeartsNoticeAction.exited);
                  },
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Thoat bai hoc'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
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
