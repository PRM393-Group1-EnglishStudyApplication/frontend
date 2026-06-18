import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../providers/leaderboard_providers.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leaderboardAsync = ref.watch(leaderboardDataProvider);
    final userAsync = ref.watch(currentUserProvider);

    final currentUserId = userAsync.maybeWhen(
      data: (user) => user.id,
      orElse: () => null,
    );

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bảng xếp hạng trống',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy hoàn thành bài học để trở thành người đầu tiên!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // Separate Top 3 and Others
        final top3 = entries.take(3).toList();
        final others = entries.skip(3).toList();

        // Find current user's rank
        final myEntry = entries.firstWhere(
          (e) => e.userId == currentUserId,
          orElse: () => const LeaderboardEntry(
            id: '',
            userId: '',
            weekStartDate: '',
            xp: 0,
            rankPosition: 0,
          ),
        );

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(leaderboardDataProvider);
              ref.invalidate(myLeaderboardProvider);
            },
            child: CustomScrollView(
              slivers: [
                // Top 3 Podium Section
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                    child: _buildPodium(context, top3, currentUserId),
                  ),
                ),

                // Leaderboard List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = others[index];
                        final isMe = entry.userId == currentUserId;
                        return _buildLeaderboardRow(context, entry, isMe);
                      },
                      childCount: others.length,
                    ),
                  ),
                ),
                // Extra padding at the bottom for banner
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
          bottomSheet: _buildPromotionBanner(context, myEntry.rankPosition),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync_problem_rounded, color: theme.colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Lỗi đồng bộ bảng xếp hạng: $err',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(leaderboardDataProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<LeaderboardEntry> top3, String? currentUserId) {
    // Sort so 2nd is left, 1st is center, 3rd is right
    LeaderboardEntry? first = top3.isNotEmpty ? top3[0] : null;
    LeaderboardEntry? second = top3.length > 1 ? top3[1] : null;
    LeaderboardEntry? third = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 2nd Place (Left)
        if (second != null)
          _buildPodiumUser(context, second, 2, 80, currentUserId == second.userId)
        else
          const SizedBox(width: 80),

        // 1st Place (Center - Taller)
        if (first != null)
          _buildPodiumUser(context, first, 1, 100, currentUserId == first.userId)
        else
          const SizedBox(width: 100),

        // 3rd Place (Right)
        if (third != null)
          _buildPodiumUser(context, third, 3, 70, currentUserId == third.userId)
        else
          const SizedBox(width: 70),
      ],
    );
  }

  Widget _buildPodiumUser(
    BuildContext context,
    LeaderboardEntry entry,
    int rank,
    double height,
    bool isMe,
  ) {
    final theme = Theme.of(context);
    final String fullName = entry.user?.fullName ?? 'Học viên';
    final avatarUrl = entry.user?.avatarUrl;

    Color podiumColor;
    Color medalColor;
    IconData? medalIcon;

    switch (rank) {
      case 1:
        podiumColor = Colors.amber.shade100;
        medalColor = Colors.amber;
        medalIcon = Icons.workspace_premium_rounded;
        break;
      case 2:
        podiumColor = Colors.grey.shade100;
        medalColor = Colors.grey.shade400;
        medalIcon = Icons.military_tech_rounded;
        break;
      case 3:
        podiumColor = Colors.orange.shade100;
        medalColor = Colors.orange.shade700;
        medalIcon = Icons.military_tech_rounded;
        break;
      default:
        podiumColor = theme.colorScheme.surfaceVariant;
        medalColor = theme.colorScheme.onSurface;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal / Crown Icon
        if (rank == 1)
          const Icon(Icons.star_rounded, color: Colors.amber, size: 28)
        else
          const SizedBox(height: 28),
        const SizedBox(height: 4),

        // Avatar
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMe ? theme.colorScheme.primary : medalColor,
                  width: isMe ? 4 : 2,
                ),
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 40 : 32,
                backgroundColor: theme.colorScheme.surfaceVariant,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        fullName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: rank == 1 ? 24 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: medalColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (medalIcon != null)
                      Icon(medalIcon, size: 10, color: Colors.white),
                    Text(
                      '$rank',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Name
        SizedBox(
          width: 90,
          child: Text(
            isMe ? 'Bạn (Bạn)' : fullName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
              color: isMe ? theme.colorScheme.primary : null,
            ),
          ),
        ),

        // XP
        Text(
          '${entry.xp} XP',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 12),

        // Pedestal base
        Container(
          width: rank == 1 ? 85 : 75,
          height: height,
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: medalColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(BuildContext context, LeaderboardEntry entry, bool isMe) {
    final theme = Theme.of(context);
    final String fullName = entry.user?.fullName ?? 'Học viên';
    final avatarUrl = entry.user?.avatarUrl;
    final int rank = entry.rankPosition;

    String subtitle = 'Học viên';
    if (rank == 4) subtitle = 'Học viên mới';
    if (isMe) subtitle = 'Đang nỗ lực';
    if (rank == 6) subtitle = 'Top 10 tuần trước';
    if (rank >= 7) subtitle = 'Thành viên chăm chỉ';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isMe ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank Number
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isMe ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.surfaceVariant,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ],
        ),
        title: Text(
          isMe ? 'Bạn (Bạn)' : fullName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
            color: isMe ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isMe ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8) : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          '${entry.xp} XP',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isMe ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionBanner(BuildContext context, int myRank) {
    final theme = Theme.of(context);
    
    // Check if promotion banner should show. 
    // In Stitch screen: "Vùng Thăng Hạng / Giữ vững phong độ để lọt vào Top 3!"
    final inPromotionZone = myRank > 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              color: theme.colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vùng Thăng Hạng',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    inPromotionZone
                        ? 'Giữ vững phong độ để lọt vào Top 3!'
                        : 'Bạn đang dẫn đầu! Hãy giữ vững phong độ!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
