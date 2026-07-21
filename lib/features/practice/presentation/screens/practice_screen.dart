import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../hearts/presentation/providers/heart_providers.dart';
import '../../../lessons/domain/entities/exercise_entities.dart';
import '../../../multiplayer/presentation/screens/multiplayer_lobby_screen.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../providers/practice_providers.dart';
import 'practice_pack_screen.dart';
import 'package:prm_frontend/features/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:prm_frontend/features/flashcards/presentation/screens/flashcard_home_screen.dart';

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
    final learnedVocabularyAsync = ref.watch(learnedVocabularyCountProvider);
    final wrongAnswersAsync = ref.watch(wrongAnswerPackProvider);

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
          ref.invalidate(learnedVocabularyCountProvider);
          ref.invalidate(wrongAnswerPackProvider);
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
                        'Cùng ôn luyện và theo dõi tiến bộ mỗi ngày.',
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
                          theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.6,
                          ),
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
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
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
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
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
                                      builder: (context) =>
                                          const PracticePackScreen(),
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
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final dueCountAsync = ref.watch(dueCountProvider);
                final int dueCount = dueCountAsync.maybeWhen(data: (value) => value, orElse: () => 0);

                return Card(
                  elevation: 4,
                  shadowColor: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.tertiaryContainer.withValues(alpha: 0.6),
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
                                color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.style_rounded,
                                color: theme.colorScheme.tertiary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Flashcards',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dueCount > 0
                                        ? '$dueCount từ cần ôn hôm nay'
                                        : 'Ôn từ vựng đã học bằng thẻ lật',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (dueCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$dueCount',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onTertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const FlashcardHomeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.style_rounded),
                          label: const Text('Ôn Flashcards'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Card(
              elevation: 4,
              shadowColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.secondaryContainer.withValues(
                        alpha: 0.6,
                      ),
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
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.groups_rounded,
                            color: theme.colorScheme.secondary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thách Đấu 1v1',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Đấu quiz thời gian thực cùng bạn bè hoặc người học khác.',
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
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const MultiplayerLobbyScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text('Bắt đầu đấu 1v1'),
                    ),
                  ],
                ),
              ),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricCard(
              icon: Icons.menu_book_rounded,
              color: Colors.indigo,
              label: 'Từ vựng đã học',
              value: learnedVocabularyAsync.when(
                data: (value) => '$value',
                loading: () => '--',
                error: (_, __) => '--',
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Can xem lai',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            wrongAnswersAsync.when(
              loading: () => const _WrongAnswersLoadingCard(),
              error: (_, __) => _WrongAnswersErrorCard(
                onRefresh: () => ref.invalidate(wrongAnswerPackProvider),
              ),
              data: (pack) => pack.total == 0
                  ? const _WrongAnswersEmptyCard()
                  : _WrongAnswersCard(
                      count: pack.total,
                      onView: () => _showWrongAnswersSheet(
                        context,
                        pack.items,
                        pack.total,
                      ),
                      onStart: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const PracticePackScreen.wrongAnswers(),
                          ),
                        );
                        ref.invalidate(wrongAnswerPackProvider);
                      },
                    ),
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

  const _MetricCard({
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
          ],
        ),
      ),
    );
  }
}

class _WrongAnswersLoadingCard extends StatelessWidget {
  const _WrongAnswersLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      child: SizedBox(
        height: 124,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _WrongAnswersErrorCard extends StatelessWidget {
  final VoidCallback onRefresh;

  const _WrongAnswersErrorCard({required this.onRefresh});

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
            Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Không tải được câu cần ôn',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vui lòng kiểm tra kết nối và thử tải lại.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WrongAnswersEmptyCard extends StatelessWidget {
  const _WrongAnswersEmptyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green.shade700,
              size: 30,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa có câu sai cần ôn',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('Những câu bạn trả lời sai sẽ xuất hiện tại đây.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WrongAnswersCard extends StatelessWidget {
  final int count;
  final VoidCallback onView;
  final VoidCallback onStart;

  const _WrongAnswersCard({
    required this.count,
    required this.onView,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.replay_circle_filled_rounded,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$count câu cần ôn lại',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Làm đúng để loại câu hỏi khỏi danh sách cần xem lại.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Xem các câu đã sai'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Luyện lại câu sai'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showWrongAnswersSheet(
  BuildContext context,
  List<Exercise> exercises,
  int total,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Các câu bạn đã làm sai',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total > exercises.length
                          ? 'Hiển thị ${exercises.length} câu sai gần nhất trong tổng số $total câu.'
                          : '$total câu đang cần xem lại.',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    return _WrongAnswerReviewCard(
                      index: index + 1,
                      exercise: exercises[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _WrongAnswerReviewCard extends StatelessWidget {
  final int index;
  final Exercise exercise;

  const _WrongAnswerReviewCard({required this.index, required this.exercise});

  String _displayAnswer(String? answer) {
    final value = answer?.trim() ?? '';
    if (value.isEmpty) {
      return 'Chưa nhập câu trả lời';
    }
    for (final option in exercise.options) {
      if (option.id == value) {
        return option.optionText;
      }
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
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
            Text(
              'Câu $index',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              exercise.question,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _AnswerLine(
              label: 'Câu trả lời của bạn',
              value: _displayAnswer(exercise.lastUserAnswer),
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            _AnswerLine(
              label: 'Đáp án đúng',
              value: _displayAnswer(exercise.correctAnswer),
              color: Colors.green.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnswerLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: <InlineSpan>[
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
