import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prm_frontend/features/flashcards/data/models/flashcard_model.dart';
import 'package:prm_frontend/features/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:prm_frontend/features/flashcards/presentation/screens/flashcard_summary_screen.dart';
import 'package:prm_frontend/features/flashcards/presentation/widgets/flip_card.dart';
import 'package:prm_frontend/features/flashcards/presentation/widgets/swipe_deck.dart';

// FR-6/FR-7/FR-8/FR-9: man on - stack the chong, lat 3D, vuot/bam nut, undo, progress, thoat giua chung
class FlashcardSessionScreen extends ConsumerStatefulWidget {
  final FlashcardSource source;
  final String? lessonId;

  const FlashcardSessionScreen({super.key, required this.source, this.lessonId});

  @override
  ConsumerState<FlashcardSessionScreen> createState() => _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState extends ConsumerState<FlashcardSessionScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, String> _audioUrlCache = {};
  bool _isPlayingAudio = false;
  bool _submitTriggered = false;
  bool _navigatedToSummary = false;

  FlashcardSessionKey get _key => (source: widget.source, lessonId: widget.lessonId);

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // TTS: goi /api/tts?format=link lay URL -> phat bang audioplayers; cache URL trong phien (§8)
  Future<void> _playPronunciation(String word) async {
    setState(() => _isPlayingAudio = true);
    try {
      String? url = _audioUrlCache[word];
      url ??= await ref.read(flashcardRemoteDataSourceProvider).getTtsAudioUrl(word);
      _audioUrlCache[word] = url;
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {
      // Loi TTS chi disable nut loa, khong chan phien
    } finally {
      if (mounted) {
        setState(() => _isPlayingAudio = false);
      }
    }
  }

  void _scheduleSubmitIfNeeded(FlashcardSessionState state) {
    if (_submitTriggered || state.isSubmitting || state.submitResult != null || state.submitError != null) {
      return;
    }
    _submitTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(flashcardSessionProvider(_key).notifier).submit();
    });
  }

  Future<void> _handleExit() async {
    final state = ref.read(flashcardSessionProvider(_key));
    if (state.buffer.isNotEmpty && !state.isSessionComplete) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thoát phiên ôn?'),
          content: Text('Bạn đã ôn ${state.progress}/${state.total} thẻ. Kết quả đã ôn sẽ được lưu lại.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Ở lại')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Thoát')),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }
    if (!mounted) return;
    if (state.buffer.isNotEmpty) {
      await ref.read(flashcardSessionProvider(_key).notifier).submit();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(flashcardSessionProvider(_key));

    ref.listen<FlashcardSessionState>(flashcardSessionProvider(_key), (previous, next) {
      if (!_navigatedToSummary && next.submitResult != null && next.isSessionComplete) {
        _navigatedToSummary = true;
        final int knownCount = next.buffer.where((e) => e.result == 'known').length;
        final int unknownCount = next.buffer.where((e) => e.result == 'unknown').length;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (context) => FlashcardSummaryScreen(
                result: next.submitResult!,
                knownCount: knownCount,
                unknownCount: unknownCount,
                source: widget.source,
                lessonId: widget.lessonId,
              ),
            ),
          );
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ôn Flashcards'),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: _handleExit),
      ),
      body: _buildBody(context, theme, state),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, FlashcardSessionState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadError != null) {
      return _buildLoadErrorState(theme, state);
    }
    if (state.isDeckEmpty) {
      return _buildEmptyState(context, theme);
    }
    if (state.isSessionComplete) {
      if (state.submitError != null) {
        return _buildSubmitErrorState(theme, state);
      }
      _scheduleSubmitIfNeeded(state);
      return const Center(child: CircularProgressIndicator());
    }
    return _buildSessionBody(theme, state);
  }

  Widget _buildLoadErrorState(ThemeData theme, FlashcardSessionState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync_problem_rounded, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text('Lỗi tải phiên ôn: ${state.loadError}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(flashcardSessionProvider(_key)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // FR-11: trang thai rong than thien
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              'Không có từ cần ôn',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử ôn bộ Từ yêu thích hoặc học thêm lesson mới nhé.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Về trang chính'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitErrorState(ThemeData theme, FlashcardSessionState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text('Không lưu được kết quả: ${state.submitError}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(flashcardSessionProvider(_key).notifier).submit(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionBody(ThemeData theme, FlashcardSessionState state) {
    final FlashcardModel card = state.currentCard!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.progress}/${state.total}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (state.canUndo)
                    TextButton.icon(
                      onPressed: () => ref.read(flashcardSessionProvider(_key).notifier).undo(),
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text('Hoàn tác'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.total == 0 ? 0 : state.progress / state.total,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (state.afterNextCard != null) _buildPeekCard(theme, offsetIndex: 2),
                if (state.nextCard != null) _buildPeekCard(theme, offsetIndex: 1),
                SwipeableCard(
                  key: ValueKey(card.vocabularyId),
                  onSwiped: (direction) {
                    ref
                        .read(flashcardSessionProvider(_key).notifier)
                        .swipe(direction == SwipeDirection.right ? 'known' : 'unknown');
                  },
                  onTap: () => ref.read(flashcardSessionProvider(_key).notifier).flip(),
                  child: _buildCardFace(theme, card, state.isFlipped),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AccessibilityButton(
                icon: Icons.close_rounded,
                color: Colors.orange,
                label: 'Chưa thuộc',
                onPressed: () => ref.read(flashcardSessionProvider(_key).notifier).swipe('unknown'),
              ),
              _AccessibilityButton(
                icon: Icons.check_rounded,
                color: Colors.green,
                label: 'Đã thuộc',
                onPressed: () => ref.read(flashcardSessionProvider(_key).notifier).swipe('known'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeekCard(ThemeData theme, {required int offsetIndex}) {
    return Transform.translate(
      offset: Offset(0, offsetIndex * 10.0),
      child: Transform.scale(
        scale: 1 - offsetIndex * 0.04,
        child: Container(
          width: double.infinity,
          height: 380,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace(ThemeData theme, FlashcardModel card, bool isFlipped) {
    return SizedBox(
      width: double.infinity,
      height: 380,
      child: FlipCard(
        isFlipped: isFlipped,
        front: _buildFrontFace(theme, card),
        back: _buildBackFace(theme, card),
      ),
    );
  }

  Widget _buildFrontFace(ThemeData theme, FlashcardModel card) {
    final String pronunciation = card.pronunciation ?? '';
    return _cardContainer(
      theme,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.word,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (pronunciation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              pronunciation,
              style: theme.textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          IconButton.filledTonal(
            onPressed: _isPlayingAudio ? null : () => _playPronunciation(card.word),
            icon: _isPlayingAudio
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.volume_up_rounded),
          ),
          const SizedBox(height: 24),
          Text(
            'Chạm để xem nghĩa',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildBackFace(ThemeData theme, FlashcardModel card) {
    final String example = card.exampleSentence ?? '';
    return _cardContainer(
      theme,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.meaning,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (example.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(example, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _cardContainer(ThemeData theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _AccessibilityButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  const _AccessibilityButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            minimumSize: const Size(56, 56),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
