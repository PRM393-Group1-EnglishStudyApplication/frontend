import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/vocabulary_model.dart';
import '../data/services/vocabulary_service.dart';
import '../../auth/presentation/providers/auth_providers.dart';

final _vocabularyServiceProvider = Provider<VocabularyService>((ref) {
  return VocabularyService(ref.watch(authDioProvider));
});

final _vocabularyProvider = FutureProvider.family<List<VocabularyModel>, String>(
  (ref, lessonId) =>
      ref.watch(_vocabularyServiceProvider).getVocabularyForLesson(lessonId),
);

class VocabularyCardPage extends ConsumerStatefulWidget {
  final String lessonId;

  const VocabularyCardPage({super.key, required this.lessonId});

  @override
  ConsumerState<VocabularyCardPage> createState() => _VocabularyCardPageState();
}

class _VocabularyCardPageState extends ConsumerState<VocabularyCardPage> {
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentPage = 0;
  bool _isPlaying = false;

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String? url) async {
    if (url == null || url.isEmpty) return;
    setState(() => _isPlaying = true);
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vocabAsync = ref.watch(_vocabularyProvider(widget.lessonId));

    return Scaffold(
      appBar: AppBar(
        title: vocabAsync.maybeWhen(
          data: (list) => Text('${_currentPage + 1} / ${list.length}'),
          orElse: () => const Text('Vocabulary'),
        ),
        centerTitle: true,
      ),
      body: vocabAsync.when(
        data: (words) {
          if (words.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.translate, size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No vocabulary in this lesson', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return Column(
            children: [
              LinearProgressIndicator(
                value: ((_currentPage + 1) / words.length),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: words.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _VocabCard(
                    vocab: words[i],
                    isPlaying: _isPlaying && _currentPage == i,
                    onPlay: () => _playAudio(words[i].audioUrl),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: const Text('Previous'),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _currentPage < words.length - 1
                            ? () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                )
                            : () => context.pop(),
                        child: Text(_currentPage < words.length - 1 ? 'Next' : 'Finish'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Failed to load vocabulary', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(_vocabularyProvider(widget.lessonId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VocabCard extends StatelessWidget {
  final VocabularyModel vocab;
  final bool isPlaying;
  final VoidCallback onPlay;

  const _VocabCard({
    required this.vocab,
    required this.isPlaying,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                vocab.word,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (vocab.pronunciation != null && vocab.pronunciation!.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vocab.pronunciation!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: onPlay,
                      icon: Icon(
                        isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                      ),
                      iconSize: 20,
                    ),
                  ],
                )
              else if (vocab.audioUrl != null && vocab.audioUrl!.isNotEmpty)
                IconButton.filledTonal(
                  onPressed: onPlay,
                  icon: Icon(
                    isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                  ),
                ),
              const SizedBox(height: 24),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                vocab.meaning,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (vocab.exampleSentence != null && vocab.exampleSentence!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '"${vocab.exampleSentence}"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
