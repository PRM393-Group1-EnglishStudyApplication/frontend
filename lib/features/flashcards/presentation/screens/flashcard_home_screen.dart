import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prm_frontend/features/flashcards/data/models/flashcard_model.dart';
import 'package:prm_frontend/features/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:prm_frontend/features/flashcards/presentation/screens/flashcard_session_screen.dart';
import 'package:prm_frontend/features/flashcards/presentation/widgets/box_stats_bar.dart';
import 'package:prm_frontend/features/progress/presentation/providers/progress_providers.dart';

// FR-5: chon bo Hom nay / Yeu thich / Theo lesson; hien thong ke 5 hop
class FlashcardHomeScreen extends ConsumerWidget {
  const FlashcardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dueSessionAsync = ref.watch(flashcardSessionProvider((source: FlashcardSource.due, lessonId: null)));

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Chọn bộ thẻ để ôn',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _SourceCard(
            icon: Icons.today_rounded,
            color: theme.colorScheme.primary,
            title: 'Hôm nay',
            subtitle: dueSessionAsync.isLoading
                ? 'Đang tải...'
                : dueSessionAsync.deck.isEmpty
                ? 'Không có từ cần ôn 🎉'
                : '${dueSessionAsync.deck.length} từ cần ôn (SRS)',
            onTap: () => _openSession(context, FlashcardSource.due, null),
          ),
          const SizedBox(height: 12),
          _SourceCard(
            icon: Icons.favorite_rounded,
            color: Colors.pink,
            title: 'Từ yêu thích',
            subtitle: 'Ôn tự do các từ đã đánh dấu yêu thích',
            onTap: () => _openSession(context, FlashcardSource.favorites, null),
          ),
          const SizedBox(height: 12),
          _LessonSourceCard(onPickLesson: (lessonId) => _openSession(context, FlashcardSource.lesson, lessonId)),
          const SizedBox(height: 28),
          Text(
            'Thống kê 5 hộp (Leitner)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: dueSessionAsync.isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                  : BoxStatsBar(boxCounts: dueSessionAsync.boxCounts),
            ),
          ),
        ],
      ),
    );
  }

  void _openSession(BuildContext context, FlashcardSource source, String? lessonId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FlashcardSessionScreen(source: source, lessonId: lessonId),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _LessonSourceCard extends ConsumerWidget {
  final ValueChanged<String> onPickLesson;

  const _LessonSourceCard({required this.onPickLesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(progressEntriesProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withValues(alpha: 0.15),
          child: const Icon(Icons.menu_book_rounded, color: Colors.teal),
        ),
        title: const Text('Theo lesson', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Chọn từ vựng của một bài học đã học'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          final completedLessons = progressAsync.maybeWhen(
            data: (entries) => entries.where((e) => e.isCompleted).toList(),
            orElse: () => const [],
          );

          if (completedLessons.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bạn chưa hoàn thành lesson nào để chọn.')),
            );
            return;
          }

          final String? lessonId = await showModalBottomSheet<String>(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (context) {
              return SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Chọn lesson để ôn',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    for (final entry in completedLessons)
                      ListTile(
                        title: Text(entry.lessonTitle),
                        onTap: () => Navigator.of(context).pop(entry.lessonId),
                      ),
                  ],
                ),
              );
            },
          );

          if (lessonId != null) {
            onPickLesson(lessonId);
          }
        },
      ),
    );
  }
}
