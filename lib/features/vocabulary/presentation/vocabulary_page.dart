import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class VocabularyPage extends StatelessWidget {
  const VocabularyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Từ vựng',
      icon: Icons.menu_book_rounded,
      subtitle:
          'Danh sách từ vựng và từ yêu thích sẽ xuất hiện ở đây.\n'
          'Kết nối API: /api/vocabulary, /api/favorites/me.',
    );
  }
}
