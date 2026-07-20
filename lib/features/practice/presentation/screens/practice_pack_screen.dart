import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prm_frontend/core/utils/matching_codec.dart';
import 'package:prm_frontend/features/achievements/presentation/providers/achievements_providers.dart';
import 'package:prm_frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:prm_frontend/features/hearts/presentation/providers/heart_providers.dart';
import 'package:prm_frontend/features/leaderboard/presentation/providers/leaderboard_providers.dart';
import 'package:prm_frontend/features/lessons/domain/entities/exercise_entities.dart';
import 'package:prm_frontend/features/lessons/presentation/widgets/matching_exercise.dart';
import 'package:prm_frontend/features/lessons/presentation/widgets/out_of_hearts_notice_sheet.dart';
import 'package:prm_frontend/features/practice/presentation/providers/practice_providers.dart';
import 'package:prm_frontend/features/progress/presentation/providers/progress_providers.dart';

enum PracticeMode { random, wrongAnswers }

class PracticePackScreen extends ConsumerStatefulWidget {
  final PracticeMode mode;

  const PracticePackScreen({super.key, this.mode = PracticeMode.random});

  const PracticePackScreen.wrongAnswers({super.key})
    : mode = PracticeMode.wrongAnswers;

  @override
  ConsumerState<PracticePackScreen> createState() => _PracticePackScreenState();
}

class _PracticePackScreenState extends ConsumerState<PracticePackScreen> {
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

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
  int? _remainingWrongAnswers;

  bool get _isWrongAnswerReview => widget.mode == PracticeMode.wrongAnswers;

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AsyncValue<List<Exercise>> practicePackAsync;
    if (_isWrongAnswerReview) {
      practicePackAsync = ref
          .watch(wrongAnswerPackProvider)
          .whenData((pack) => pack.items);
    } else {
      practicePackAsync = ref.watch(practicePackProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isWrongAnswerReview ? 'Luyện lại câu sai' : 'Luyện Tập Ngẫu Nhiên',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showQuitConfirmation(),
        ),
      ),
      body: practicePackAsync.when(
        data: (exercises) {
          if (_isSubmitting) {
            return _buildAnalyzingStep(context);
          }
          if (_showResult && _result != null) {
            return _buildResultStep(context);
          }
          return _buildExerciseStep(context, exercises);
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
                'Lỗi tải bài luyện tập: $err',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _refreshPack,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
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
            Text(
              _isWrongAnswerReview
                  ? 'Bạn không còn câu sai cần ôn lại.'
                  : 'Ngân hàng câu hỏi hiện tại đang trống.',
            ),
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
                'Câu hỏi ${_currentExerciseIndex + 1}/${exercises.length}',
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
                // Display Question
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
        if (_isChecked)
          _buildCheckFeedbackBanner(theme, exercise.correctAnswer),

        // Action button (Check / Continue)
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: FilledButton(
            key: const Key('practice-action-button'),
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

      // Check correctness
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

      if (!isCorrect && !_isWrongAnswerReview) {
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
        // Submit practice pack to server
        _submitPracticeAnswers();
      }
    }
  }

  // Multiple choice options list
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
  Widget _buildCheckFeedbackBanner(ThemeData theme, String correctAnswer) {
    final isCorrect = _isAnswerCorrect;
    final color = isCorrect ? Colors.green : Colors.red;
    return Container(
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16.0),
      child: Row(
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
                    'Đáp án đúng: $correctAnswer',
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
    final success = _isWrongAnswerReview
        ? (_remainingWrongAnswers ?? 0) == 0
        : res.score >= 70;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(
            success ? Icons.emoji_events_rounded : Icons.stars_outlined,
            size: 96,
            color: success ? Colors.amber : theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _isWrongAnswerReview
                ? success
                      ? 'Bạn đã sửa hết câu sai!'
                      : 'Đã hoàn thành lượt ôn!'
                : success
                ? 'Hoàn thành Luyện tập!'
                : 'Cố gắng lên nhé!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isWrongAnswerReview
                ? success
                      ? 'Các câu bạn vừa sửa đúng đã được loại khỏi danh sách cần ôn.'
                      : 'Câu làm đúng đã được xóa; câu còn sai vẫn được giữ để bạn luyện tiếp.'
                : success
                ? 'Bạn đã hoàn thành xuất sắc bài luyện tập ngẫu nhiên!'
                : 'Điểm số chưa đủ 70% để vượt qua bài luyện tập. Hãy rèn luyện thêm nhé!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

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
                    _isWrongAnswerReview ? 'Còn lại' : 'Kinh nghiệm',
                    _isWrongAnswerReview
                        ? '${_remainingWrongAnswers ?? 0} câu'
                        : '+${res.earnedXp} XP',
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          FilledButton(
            onPressed: () async {
              if (_isWrongAnswerReview && (_remainingWrongAnswers ?? 0) > 0) {
                _restartWrongAnswerReview();
                return;
              }
              await ref.read(currentUserProvider.notifier).loadUser();
              if (!_isWrongAnswerReview) {
                await ref.read(heartProvider.notifier).loadHearts();
              }
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pop();
            },
            child: Text(
              _isWrongAnswerReview && (_remainingWrongAnswers ?? 0) > 0
                  ? 'Luyện tiếp'
                  : 'Hoàn thành',
            ),
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
  Future<void> _submitPracticeAnswers() async {
    setState(() {
      _isSubmitting = true;
    });

    final List<Map<String, dynamic>> answersList = _userAnswers.entries.map((
      e,
    ) {
      return <String, dynamic>{'exerciseId': e.key, 'userAnswer': e.value};
    }).toList();

    try {
      final repository = ref.read(practiceRepositoryProvider);
      if (_isWrongAnswerReview) {
        final reviewResult = await repository.submitWrongAnswerReview(
          answersList,
        );
        ref.invalidate(wrongAnswerPackProvider);
        if (!mounted) {
          return;
        }
        setState(() {
          _result = LessonSubmissionResult(
            totalQuestions: reviewResult.totalQuestions,
            correctAnswers: reviewResult.correctAnswers,
            score: reviewResult.score,
            earnedXp: 0,
            currentHearts: 0,
            unlockedAchievements: const <dynamic>[],
          );
          _remainingWrongAnswers = reviewResult.remainingWrongAnswers;
          _isSubmitting = false;
          _showResult = true;
        });
        return;
      }

      final res = await repository.submitPracticePack(answersList);

      await ref.read(heartProvider.notifier).loadHearts();
      ref.invalidate(progressSummaryProvider);
      await ref.read(currentUserProvider.notifier).loadUser();
      ref.invalidate(allAchievementsDataProvider);
      ref.invalidate(myAchievementsDataProvider);
      ref.invalidate(combinedAchievementsProvider);
      ref.invalidate(leaderboardDataProvider);
      ref.invalidate(myLeaderboardProvider);
      ref.invalidate(leaderboardViewProvider);

      if (!mounted) {
        return;
      }
      setState(() {
        _result = res;
        _isSubmitting = false;
        _showResult = true;
      });

      if (res.unlockedAchievements.isNotEmpty) {
        _showUnlockedAchievementsDialog(res.unlockedAchievements);
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi nộp bài làm: $err')));
      }
    }
  }

  void _refreshPack() {
    if (_isWrongAnswerReview) {
      ref.invalidate(wrongAnswerPackProvider);
    } else {
      ref.invalidate(practicePackProvider);
    }
  }

  void _restartWrongAnswerReview() {
    _answerController.clear();
    _answerFocusNode.unfocus();
    ref.invalidate(wrongAnswerPackProvider);
    setState(() {
      _currentExerciseIndex = 0;
      _userAnswers.clear();
      _currentInputAnswer = '';
      _selectedOptionText = null;
      _matchingAnswer = null;
      _isChecked = false;
      _isAnswerCorrect = false;
      _isSubmitting = false;
      _showResult = false;
      _result = null;
      _remainingWrongAnswers = null;
    });
  }

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
          title: const Text('Thoát bài luyện tập?'),
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
