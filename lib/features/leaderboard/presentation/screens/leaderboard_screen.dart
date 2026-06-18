import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leaderboard_entry.dart';
import '../providers/leaderboard_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leaderboardAsync = ref.watch(leaderboardViewProvider);

    return leaderboardAsync.when(
      data: (viewData) {
        final entries = viewData.entries;
        final myEntry = viewData.myEntry;
        final myUserId = myEntry.userId;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(leaderboardDataProvider);
              ref.invalidate(myLeaderboardProvider);
              ref.invalidate(leaderboardViewProvider);
            },
            child: entries.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: <Widget>[
                      const SizedBox(height: 120),
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bang xep hang trong',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hoan thanh bai hoc dau tien de co XP tren bang xep hang tuan.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : CustomScrollView(
                    slivers: <Widget>[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                          child: _Podium(entries: entries.take(3).toList(), myUserId: myUserId),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
                        sliver: SliverList.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _LeaderboardRow(
                              entry: entry,
                              isMe: entry.userId == myUserId,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          bottomSheet: _CurrentUserRankCard(entry: myEntry),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
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
                'Unable to sync leaderboard: $err',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  ref.invalidate(leaderboardDataProvider);
                  ref.invalidate(myLeaderboardProvider);
                  ref.invalidate(leaderboardViewProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String myUserId;

  const _Podium({required this.entries, required this.myUserId});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: entries
          .map(
            (entry) => _PodiumUser(
              entry: entry,
              isMe: entry.userId == myUserId,
            ),
          )
          .toList(),
    );
  }
}

class _PodiumUser extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;

  const _PodiumUser({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rank = entry.rankPosition;
    final name = isMe ? 'You' : entry.user?.fullName ?? 'Learner';
    final avatarUrl = entry.user?.avatarUrl;
    final color = switch (rank) {
      1 => Colors.amber,
      2 => Colors.grey,
      3 => Colors.orange,
      _ => theme.colorScheme.primary,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.workspace_premium_rounded, color: color, size: rank == 1 ? 34 : 28),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: rank == 1 ? 38 : 32,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase())
              : null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 92,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isMe ? theme.colorScheme.primary : null,
            ),
          ),
        ),
        Text('${entry.xp} XP'),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;

  const _LeaderboardRow({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = isMe ? 'You' : entry.user?.fullName ?? 'Learner';
    final avatarUrl = entry.user?.avatarUrl;

    return Card(
      elevation: 0,
      color: isMe ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 28,
              child: Text(
                entry.rankPosition > 0 ? '#${entry.rankPosition}' : '--',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isMe ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase())
                  : null,
            ),
          ],
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.w600),
        ),
        subtitle: Text(isMe ? 'Current user' : 'Weekly XP'),
        trailing: Text(
          '${entry.xp} XP',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CurrentUserRankCard extends StatelessWidget {
  final LeaderboardEntry entry;

  const _CurrentUserRankCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRank = entry.rankPosition > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Icon(Icons.person_pin_circle_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasRank
                    ? 'Your weekly rank is #${entry.rankPosition} with ${entry.xp} XP.'
                    : 'You are not ranked this week yet. Complete a lesson to earn XP.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
