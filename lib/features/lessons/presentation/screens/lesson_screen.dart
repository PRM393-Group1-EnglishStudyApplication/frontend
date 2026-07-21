import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/achievements/presentation/providers/achievements_providers.dart';
import '../../../../features/hearts/presentation/providers/heart_providers.dart';
import '../../../../features/leaderboard/presentation/providers/leaderboard_providers.dart';
import '../../../../features/progress/presentation/providers/progress_providers.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/exercise_entities.dart';
import '../widgets/out_of_hearts_notice_sheet.dart';
import '../widgets/matching_exercise.dart';
import 'package:prm_frontend/core/utils/matching_codec.dart';
import 'package:prm_frontend/features/explanations/presentation/widgets/ai_explanation_sheet.dart';
import '../providers/lessons_providers.dart';
import '../providers/course_providers.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  bool _isLearningVocab = true;
  int _currentVocabIndex = 0;

  bool _isDoingExercises = false;
  int _currentExerciseIndex = 0;
  final Map<String, String> _userAnswers = {};
  String _currentInputAnswer = '';
  String? _selectedOptionText;
  String? _matchingAnswer;

  bool _isChecked = false;
  bool _isAnswerCorrect = false;

  bool _isSubmitting = false;
  bool _showResult = false;
  LessonSubmissionResult? _result;

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonDetailAsync = ref.watch(
      lessonDetailDataProvider(widget.lesson.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showQuitConfirmation(),
        ),
      ),
      body: lessonDetailAsync.when(
        data: (detail) {
          if (_isLearningVocab) {
            return _buildVocabStep(context, detail.vocabulary);
          }
          if (_isDoingExercises) {
            return _buildExerciseStep(context, detail.exercises);
          }
          if (_isSubmitting) {
            return _buildAnalyzingStep(context);
          }
          if (_showResult && _result != null) {
            return _buildResultStep(context);
          }
          return const SizedBox.shrink();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sync_problem_rounded,
                color: theme.colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải bài học: $err',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () =>
                    ref.invalidate(lessonDetailDataProvider(widget.lesson.id)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vocab Step
  Widget _buildVocabStep(BuildContext context, List<Vocabulary> vocabulary) {
    final theme = Theme.of(context);
    if (vocabulary.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bài học này không có từ vựng.'),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('lesson-start-exercises-button'),
              onPressed: () {
                setState(() {
                  _isLearningVocab = false;
                  _isDoingExercises = true;
                });
              },
              child: const Text('Bắt đầu làm bài tập'),
            ),
          ],
        ),
      );
    }

    final vocab = vocabulary[_currentVocabIndex];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step progress indicator
          Text(
            'Học Từ Vựng (${_currentVocabIndex + 1}/${vocabulary.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (vocab.imageUrl?.trim().isNotEmpty ?? false) ...[
                        _VocabularyImage(
                          imageUrl: vocab.imageUrl!.trim(),
                          semanticLabel: 'Minh họa cho từ ${vocab.word}',
                        ),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        vocab.word,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        vocab.pronunciation,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Divider(height: 40),
                      Text(
                        'Ý nghĩa',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vocab.meaning,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Ví dụ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vocab.exampleSentence,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_currentVocabIndex > 0)
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentVocabIndex--;
                    });
                  },
                  child: const Text('Trước'),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('lesson-vocabulary-action-button'),
                  onPressed: () {
                    if (_currentVocabIndex < vocabulary.length - 1) {
                      setState(() {
                        _currentVocabIndex++;
                      });
                    } else {
                      setState(() {
                        _isLearningVocab = false;
                        _isDoingExercises = true;
                      });
                    }
                  },
                  child: Text(
                    _currentVocabIndex < vocabulary.length - 1
                        ? 'Từ tiếp theo'
                        : 'Bắt đầu làm bài tập',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Exercise Step
  Widget _buildExerciseStep(BuildContext context, List<Exercise> exercises) {
    final theme = Theme.of(context);
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bài học này không có bài tập nào.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      );
    }

    final exercise = exercises[_currentExerciseIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Linear progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentExerciseIndex) / exercises.length,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bài tập ${_currentExerciseIndex + 1}/${exercises.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Consumer(
                    builder: (context, ref, child) {
                      final heartState = ref.watch(heartProvider);
                      return Text(
                        '${heartState.hearts?.currentHearts ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Display Question/Prompt
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      exercise.question,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Render Input based on type
                if (exercise.exerciseType == 'multiple_choice')
                  _buildMultipleChoiceInput(theme, exercise.options)
                else if (exercise.exerciseType == 'matching' &&
                    MatchingCodec.decodePairs(exercise.options).length >= 2)
                  MatchingExercise(
                    key: ValueKey(exercise.id),
                    options: exercise.options,
                    enabled: !_isChecked,
                    onAnswerChanged: (ans) {
                      setState(() {
                        _matchingAnswer = ans;
                      });
                    },
                  )
                else
                  _buildTextInput(theme),
              ],
            ),
          ),
        ),

        // Result check banner
        if (_isChecked) _buildCheckFeedbackBanner(theme, exercise),

        // Action button (Check / Continue)
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: FilledButton(
            key: const Key('lesson-action-button'),
            onPressed: _isActionEnabled()
                ? () => _handleActionButton(exercises)
                : null,
            child: Text(_isChecked ? 'Tiếp tục' : 'Kiểm tra'),
          ),
        ),
      ],
    );
  }

  bool _isActionEnabled() {
    if (_isChecked) {
      return true;
    }
    if (_selectedOptionText != null && _selectedOptionText!.isNotEmpty) {
      return true;
    }
    if (_currentInputAnswer.trim().isNotEmpty) {
      return true;
    }
    if (_matchingAnswer != null && _matchingAnswer!.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> _handleActionButton(List<Exercise> exercises) async {
    final exercise = exercises[_currentExerciseIndex];
    if (!_isChecked) {
      // Perform Check
      final String userAnswer = exercise.exerciseType == 'multiple_choice'
          ? (_selectedOptionText ?? '')
          : exercise.exerciseType == 'matching'
          ? (_matchingAnswer ?? '')
          : _currentInputAnswer.trim();

      _userAnswers[exercise.id] = userAnswer;

      // Simple normalize and match correct answer
      final isCorrect =
          userAnswer.toLowerCase().trim() ==
              exercise.correctAnswer.toLowerCase().trim() ||
          (exercise.exerciseType == 'multiple_choice' &&
              exercise.options.any(
                (o) =>
                    o.optionText.toLowerCase().trim() ==
                        userAnswer.toLowerCase().trim() &&
                    o.isCorrect,
              ));

      setState(() {
        _isChecked = true;
        _isAnswerCorrect = isCorrect;
      });

      if (!isCorrect) {
        // Keep the exercise feedback responsive. The submit response remains
        // the source of truth and reconciles the count with the backend.
        final bool canContinue = await ref
            .read(heartProvider.notifier)
            .deductHeartOnError();
        if (!canContinue && mounted) {
          final OutOfHeartsNoticeAction? action =
              await showOutOfHeartsNoticeSheet(context);
          if (!mounted) {
            return;
          }
          if (action == OutOfHeartsNoticeAction.exited) {
            Navigator.of(context).pop();
            return;
          }
        }
      }
    } else {
      // Continue to next or submit
      if (_currentExerciseIndex < exercises.length - 1) {
        _answerController.clear();
        _answerFocusNode.unfocus();
        setState(() {
          _currentExerciseIndex++;
          _isChecked = false;
          _currentInputAnswer = '';
          _selectedOptionText = null;
          _matchingAnswer = null;
        });
      } else {
        // Submit answers to server
        _submitLessonAnswers();
      }
    }
  }

  // Multiple choice option list
  Widget _buildMultipleChoiceInput(
    ThemeData theme,
    List<ExerciseOption> options,
  ) {
    return Column(
      children: options.map((opt) {
        final isSelected = _selectedOptionText == opt.optionText;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            enabled: !_isChecked,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              opt.optionText,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
            trailing: Radio<String>(
              value: opt.optionText,
              groupValue: _selectedOptionText,
              onChanged: _isChecked
                  ? null
                  : (val) {
                      setState(() {
                        _selectedOptionText = val;
                      });
                    },
            ),
            onTap: _isChecked
                ? null
                : () {
                    setState(() {
                      _selectedOptionText = opt.optionText;
                    });
                  },
          ),
        );
      }).toList(),
    );
  }

  // Text Answer Input
  Widget _buildTextInput(ThemeData theme) {
    return TextField(
      key: ValueKey('text-answer-${_currentExerciseIndex}'),
      controller: _answerController,
      focusNode: _answerFocusNode,
      enabled: !_isChecked,
      autofocus: true,
      onChanged: (val) {
        setState(() {
          _currentInputAnswer = val;
        });
      },
      decoration: InputDecoration(
        labelText: 'Nhập câu trả lời của bạn',
        hintText: 'Nhập bản dịch hoặc từ còn thiếu...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Visual Banner Feedback
  Widget _buildCheckFeedbackBanner(ThemeData theme, Exercise exercise) {
    final isCorrect = _isAnswerCorrect;
    final color = isCorrect ? Colors.green : Colors.red;
    // Dap an nguoi hoc vua gui luc bam Kiem tra (da luu trong _handleActionButton)
    final String userAnswer = _userAnswers[exercise.id] ?? '';
    // Requirement 2 v1 khong ho tro cau matching (prompt/dap an dang ma hoa cap - v2)
    final bool canExplainWithAi =
        !isCorrect && exercise.exerciseType != 'matching' && userAnswer.isNotEmpty;

    return Container(
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCorrect ? 'Chính xác! Làm rất tốt!' : 'Sai mất rồi!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đáp án đúng: ${exercise.correctAnswer}',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (canExplainWithAi) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showAiExplanationSheet(
                  context,
                  exerciseId: exercise.id,
                  userAnswer: userAnswer,
                ),
                icon: const Text('🤖'),
                label: const Text('Giải thích với AI'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Analyzing results step
  Widget _buildAnalyzingStep(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang phân tích kết quả...',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chờ chút nhé, hệ thống đang chấm điểm bài làm.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Result step screen layout
  Widget _buildResultStep(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result!;
    final success = res.score >= 70;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Big Trophy or fail icon
          Icon(
            success ? Icons.emoji_events_rounded : Icons.stars_outlined,
            size: 96,
            color: success ? Colors.amber : theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            success ? 'Bài học Hoàn thành!' : 'Cố gắng lên nhé!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            success
                ? 'Bạn đã làm rất xuất sắc và vượt qua bài học!'
                : 'Điểm số chưa đủ 70% để vượt qua bài học này. Hãy thử lại!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Scores Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResultItem(
                    context,
                    'Điểm số',
                    '${res.score}%',
                    theme.colorScheme.primary,
                  ),
                  _buildResultItem(
                    context,
                    'Đúng / Tổng',
                    '${res.correctAnswers}/${res.totalQuestions}',
                    Colors.green,
                  ),
                  _buildResultItem(
                    context,
                    'Kinh nghiệm',
                    '+${res.earnedXp} XP',
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // Continue Button
          FilledButton(
            onPressed: () async {
              // Reload user details and go back
              await ref.read(currentUserProvider.notifier).loadUser();
              await ref.read(heartProvider.notifier).loadHearts();
              if (!context.mounted) {
                return;
              }

              Navigator.of(context).pop();
            },
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // Submit action
  Future<void> _submitLessonAnswers() async {
    setState(() {
      _isDoingExercises = false;
      _isSubmitting = true;
    });

    final List<Map<String, dynamic>> answersList = _userAnswers.entries.map((
      e,
    ) {
      return <String, dynamic>{'exerciseId': e.key, 'userAnswer': e.value};
    }).toList();

    try {
      final submitLesson = ref.read(submitLessonProvider);
      final res = await submitLesson(widget.lesson.id, answersList);
      await ref.read(heartProvider.notifier).loadHearts();
      ref
          .read(completedLessonsProvider.notifier)
          .markAsCompleted(widget.lesson.id);
      ref.invalidate(progressEntriesProvider);
      ref.invalidate(progressSummaryProvider);
      ref.invalidate(learnedVocabularyCountProvider);
      await ref.read(completedLessonsProvider.notifier).reloadFromApi();
      await ref.read(currentUserProvider.notifier).loadUser();
      ref.invalidate(allAchievementsDataProvider);
      ref.invalidate(myAchievementsDataProvider);
      ref.invalidate(combinedAchievementsProvider);
      ref.invalidate(leaderboardDataProvider);
      ref.invalidate(myLeaderboardProvider);
      ref.invalidate(leaderboardViewProvider);

      setState(() {
        _result = res;
        _isSubmitting = false;
        _showResult = true;
      });

      // Show unlocked achievements dialog if any
      if (res.unlockedAchievements.isNotEmpty) {
        _showUnlockedAchievementsDialog(res.unlockedAchievements);
      }
    } catch (err) {
      setState(() {
        _isSubmitting = false;
        _isDoingExercises = true; // Rollback to let them retry nộp bài
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi nộp bài làm: $err')));
      }
    }
  }

  // Popup Mở khóa Huy hiệu mới
  void _showUnlockedAchievementsDialog(List<dynamic> achievements) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.military_tech_rounded,
            color: Colors.amber,
            size: 64,
          ),
          title: const Text(
            'Huy hiệu đã mở khóa!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: achievements.map((item) {
              final String name = item['name'] as String? ?? 'Thành tích mới';
              final String desc = item['description'] as String? ?? '';
              return Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tuyệt vời!'),
            ),
          ],
        );
      },
    );
  }

  void _showQuitConfirmation() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thoát bài học?'),
          content: const Text('Tiến trình bài tập hiện tại của bạn sẽ bị mất.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ở lại'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // dialog
                Navigator.of(context).pop(); // screen
              },
              child: const Text('Thoát'),
            ),
          ],
        );
      },
    );
  }
}

class _VocabularyImage extends StatelessWidget {
  const _VocabularyImage({required this.imageUrl, required this.semanticLabel});

  final String imageUrl;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox.square(
          dimension: 176,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              final expectedBytes = loadingProgress.expectedTotalBytes;
              final progress = expectedBytes == null
                  ? null
                  : loadingProgress.cumulativeBytesLoaded / expectedBytes;

              return ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(value: progress),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 44,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
