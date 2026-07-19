import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/multiplayer_models.dart';
import '../providers/multiplayer_match_provider.dart';
import 'multiplayer_result_screen.dart';

class MultiplayerMatchScreen extends ConsumerStatefulWidget {
  const MultiplayerMatchScreen({super.key});

  @override
  ConsumerState<MultiplayerMatchScreen> createState() => _MultiplayerMatchScreenState();
}

class _MultiplayerMatchScreenState extends ConsumerState<MultiplayerMatchScreen> {
  Timer? _timer;
  int _secondsLeft = 20;
  final TextEditingController _answerController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final state = ref.read(multiplayerMatchProvider);
      if (state.currentQuestion != null && state.status == MultiplayerStatus.playing) {
        final now = DateTime.now();
        final diff = state.currentQuestion!.endsAt.difference(now).inSeconds;
        setState(() {
          _secondsLeft = diff > 0 ? diff : 0;
        });
      }
    });
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(multiplayerMatchProvider);
    final notifier = ref.read(multiplayerMatchProvider.notifier);
    final theme = Theme.of(context);

    // Listen for finished state to redirect to results screen
    ref.listen<MultiplayerMatchState>(multiplayerMatchProvider, (previous, next) {
      if (next.status == MultiplayerStatus.finished) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => const MultiplayerResultScreen(),
          ),
        );
      }
      // Reset answer field for new question
      if (previous?.currentQuestion?.index != next.currentQuestion?.index) {
        _answerController.clear();
      }
    });

    if (state.currentQuestion == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myUserId = ref.watch(currentUserProvider).value?.id;
    final myDetails = state.players.firstWhere(
      (p) => p.userId == myUserId,
      orElse: () => state.players.isNotEmpty ? state.players.first : const MatchPlayer(userId: '', fullName: '', avatarUrl: ''),
    );
    final opponent = state.players.firstWhere(
      (p) => p.userId != myDetails.userId,
      orElse: () => MatchPlayer(userId: 'opp', fullName: 'Đối thủ', avatarUrl: ''),
    );

    // Extract score from local player score map
    final myScore = state.playerScores[myDetails.userId] ?? myDetails.score;
    final opponentScore = state.playerScores[opponent.userId] ?? opponent.score;

    final question = state.currentQuestion!;
    final exercise = question.exercise;

    return Scaffold(
      appBar: AppBar(
        title: Text('Câu hỏi ${question.index + 1}/${state.totalQuestions}'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            onPressed: () => _showQuitConfirmationDialog(context, notifier),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Disconnect banner overlay
            if (state.disconnectReason == 'disconnect')
              Container(
                color: theme.colorScheme.errorContainer,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đối thủ mất kết nối. Đang chờ kết nối lại (15 giây)...',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Live scoreboard at the top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // My profile card
                  _buildLiveScoreCard(theme, myDetails, myScore, true, state.isMySubmitLocked),
                  
                  // Countdown timer
                  _buildTimerBadge(theme, state),

                  // Opponent profile card
                  _buildLiveScoreCard(theme, opponent, opponentScore, false, false),
                ],
              ),
            ),
            const Divider(),

            // Quiz workspace
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Exercise description
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            if (exercise.audioUrl != null && exercise.audioUrl!.isNotEmpty)
                              IconButton.filledTonal(
                                icon: const Icon(Icons.volume_up_rounded, size: 32),
                                onPressed: () => _playAudio(exercise.audioUrl!),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              exercise.question,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Inputs based on type (MCQ or Text Input)
                    if (state.status == MultiplayerStatus.playing) ...[
                      if (exercise.exerciseType == 'multiple_choice')
                        _buildMultipleChoiceOptions(theme, exercise.options, notifier, state.isMySubmitLocked)
                      else
                        _buildTextInputField(theme, notifier, state.isMySubmitLocked)
                    ] else if (state.status == MultiplayerStatus.intermission) ...[
                      _buildIntermissionBanner(theme, state, myDetails.userId),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveScoreCard(
    ThemeData theme,
    MatchPlayer player,
    int score,
    bool isMe,
    bool isLocked,
  ) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: player.avatarUrl.isNotEmpty ? NetworkImage(player.avatarUrl) : null,
                child: player.avatarUrl.isEmpty ? const Icon(Icons.person, size: 16) : null,
              ),
              const SizedBox(width: 6),
              if (isLocked)
                Icon(Icons.lock_rounded, size: 16, color: theme.colorScheme.error)
              else if (!player.isConnected)
                Icon(Icons.cloud_off_rounded, size: 16, color: theme.colorScheme.error)
              else
                Icon(Icons.circle, size: 8, color: player.isReady ? Colors.green : Colors.grey),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isMe ? 'Bạn' : player.fullName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$scoređ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBadge(ThemeData theme, MultiplayerMatchState state) {
    final isIntermission = state.status == MultiplayerStatus.intermission;
    final color = isIntermission ? Colors.orange : (_secondsLeft < 5 ? Colors.red : theme.colorScheme.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isIntermission ? Icons.hourglass_empty_rounded : Icons.timer_rounded, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            isIntermission ? 'Nghỉ' : '${_secondsLeft}s',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(
    ThemeData theme,
    List<dynamic> options,
    MultiplayerMatchNotifier notifier,
    bool isLocked,
  ) {
    return Column(
      children: options.map((dynamic opt) {
        final optionText = opt.optionText as String? ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          child: ListTile(
            enabled: !isLocked,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              optionText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              notifier.submitAnswer(optionText);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInputField(
    ThemeData theme,
    MultiplayerMatchNotifier notifier,
    bool isLocked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _answerController,
          enabled: !isLocked,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Câu trả lời của bạn',
            hintText: 'Nhập bản dịch hoặc từ còn thiếu...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: isLocked
              ? null
              : () {
                  final text = _answerController.text.trim();
                  if (text.isNotEmpty) {
                    notifier.submitAnswer(text);
                  }
                },
          icon: const Icon(Icons.send_rounded),
          label: const Text('Gửi đáp án'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildIntermissionBanner(
    ThemeData theme,
    MultiplayerMatchState state,
    String myUserId,
  ) {
    final scorer = state.lastScorerUserId;
    final isMeWinner = scorer == myUserId;
    final isDraw = scorer == null;
    final bannerColor = isMeWinner ? Colors.green : (isDraw ? Colors.orange : Colors.red);
    final bannerIcon = isMeWinner ? Icons.check_circle_rounded : (isDraw ? Icons.hourglass_disabled_rounded : Icons.cancel_rounded);
    
    String titleText = 'Sai mất rồi!';
    if (isMeWinner) {
      titleText = 'Chính xác! Bạn trả lời nhanh nhất! (+10đ)';
    } else if (isDraw) {
      titleText = 'Không ai trả lời đúng câu này.';
    } else {
      titleText = 'Đối thủ đã trả lời đúng trước!';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bannerColor, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(bannerIcon, color: bannerColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titleText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: bannerColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'ĐÁP ÁN ĐÚNG:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.lastCorrectAnswer ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showQuitConfirmationDialog(BuildContext context, MultiplayerMatchNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thoát khỏi trận đấu?'),
          content: const Text('Nếu bạn thoát giữa trận, bạn sẽ bị xử THUA ngay lập tức. Bạn chắc chắn muốn thoát?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ở LẠI'),
            ),
            FilledButton(
              onPressed: () {
                notifier.leaveRoom();
                Navigator.of(context).pop(); // dialog
                Navigator.of(context).pop(); // screen
              },
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('XỬ THUA VÀ THOÁT'),
            ),
          ],
        );
      },
    );
  }
}
