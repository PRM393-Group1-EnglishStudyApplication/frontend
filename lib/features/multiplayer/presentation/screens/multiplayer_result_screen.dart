import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/multiplayer_models.dart';
import '../providers/multiplayer_match_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../leaderboard/presentation/providers/leaderboard_providers.dart';

class MultiplayerResultScreen extends ConsumerWidget {
  const MultiplayerResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Deliberately read (not watch): this is a terminal snapshot screen.
    // Watching would rebuild it into the "loading result" spinner when the
    // provider state is reset on the way out.
    final state = ref.read(multiplayerMatchProvider);
    final notifier = ref.read(multiplayerMatchProvider.notifier);
    final theme = Theme.of(context);

    final result = state.matchResult;
    if (result == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Đang tải kết quả trận đấu...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    final myUserId = ref.read(currentUserProvider).value?.id;
    final myPlayer = state.players.firstWhere(
      (p) => p.userId == myUserId,
      orElse: () => state.players.isNotEmpty ? state.players.first : const MatchPlayer(userId: '', fullName: '', avatarUrl: ''),
    );
    final opponent = state.players.firstWhere(
      (p) => p.userId != myPlayer.userId,
      orElse: () => state.players.isNotEmpty ? state.players.last : const MatchPlayer(userId: '', fullName: '', avatarUrl: ''),
    );

    final opponentUserId = opponent.userId;

    final myScore = result.scores[myUserId] ?? myPlayer.score;
    final opponentScore = result.scores[opponentUserId] ?? opponent.score;

    final isWinner = result.winnerUserId == myUserId;
    final isDraw = result.winnerUserId == null;

    final xp = result.xpAwarded[myUserId] ?? 5;

    // Result colors & iconography
    Color resultColor = Colors.red;
    IconData resultIcon = Icons.sentiment_very_dissatisfied_rounded;
    String outcomeTitle = 'THẤT BẠI';
    String outcomeSub = 'Đừng nản chí! Hãy ôn tập thêm và thử lại nhé.';

    if (isWinner) {
      resultColor = Colors.amber;
      resultIcon = Icons.military_tech_rounded;
      outcomeTitle = 'CHIẾN THẮNG';
      outcomeSub = 'Xuất sắc! Bạn đã vượt qua đối thủ một cách thuyết phục!';
    } else if (isDraw) {
      resultColor = Colors.orange;
      resultIcon = Icons.handshake_rounded;
      outcomeTitle = 'HÒA CỜ';
      outcomeSub = 'Một trận đấu cân tài cân sức giữa hai đối thủ!';
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),

              // Outcome Trophy/Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: resultColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Icon(
                          resultIcon,
                          color: resultColor,
                          size: 80,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      outcomeTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: resultColor,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        outcomeSub,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Comparison Scoreboard Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      // My profile
                      Expanded(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: myPlayer.avatarUrl.isNotEmpty ? NetworkImage(myPlayer.avatarUrl) : null,
                              child: myPlayer.avatarUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Bạn',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$myScoređ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // VS divider
                      Container(
                        height: 60,
                        width: 1.5,
                        color: theme.colorScheme.outlineVariant,
                      ),

                      // Opponent profile
                      Expanded(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: opponent.avatarUrl.isNotEmpty ? NetworkImage(opponent.avatarUrl) : null,
                              child: opponent.avatarUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              opponent.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$opponentScoređ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // XP rewards card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stars_rounded, color: Colors.orange[700], size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Kinh nghiệm nhận được',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '+$xp XP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Complete Button
              FilledButton(
                onPressed: () {
                  // Reset state notifier and disconnect
                  notifier.disconnect();

                  // Refresh user stats and leaderboards in the background —
                  // don't await, or this screen hangs until the network call
                  // finishes before returning to the practice screen.
                  ref.read(currentUserProvider.notifier).loadUser();
                  ref.invalidate(leaderboardDataProvider);
                  ref.invalidate(myLeaderboardProvider);
                  ref.invalidate(leaderboardViewProvider);

                  Navigator.of(context).pop(); // Back to PracticeScreen
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'HOÀN THÀNH',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
