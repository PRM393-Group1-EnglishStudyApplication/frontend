import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Xếp hạng',
      icon: Icons.leaderboard_rounded,
      subtitle:
          'Bảng xếp hạng và thành tích của bạn sẽ xuất hiện ở đây.\n'
          'Kết nối API: /api/leaderboard, /api/achievements/me.',
    );
  }
}
