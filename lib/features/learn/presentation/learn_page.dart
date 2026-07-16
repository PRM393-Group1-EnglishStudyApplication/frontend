import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Khoá học',
      icon: Icons.school_rounded,
      subtitle:
          'Lộ trình khoá học, bài học và bài tập sẽ xuất hiện ở đây.\n'
          'Kết nối API: /api/courses, /api/units, /api/lessons.',
    );
  }
}
