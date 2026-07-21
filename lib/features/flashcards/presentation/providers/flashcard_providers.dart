import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prm_frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:prm_frontend/features/flashcards/data/datasources/flashcard_remote_data_source.dart';
import 'package:prm_frontend/features/flashcards/data/models/flashcard_model.dart';
import 'package:prm_frontend/features/flashcards/data/models/review_result_model.dart';

final Provider<FlashcardRemoteDataSource> flashcardRemoteDataSourceProvider = Provider<FlashcardRemoteDataSource>((
  Ref ref,
) {
  final Dio dio = ref.watch(authDioProvider);
  return FlashcardRemoteDataSourceImpl(dio);
});

// Badge tab Practice: so the se hien trong phien "Hom nay" (den han + bu the moi, xem GR-4)
final AutoDisposeFutureProvider<int> dueCountProvider = FutureProvider.autoDispose<int>((Ref ref) async {
  final FlashcardRemoteDataSource dataSource = ref.watch(flashcardRemoteDataSourceProvider);
  final session = await dataSource.getSession(FlashcardSource.due);
  return session.cards.length;
});

typedef FlashcardSessionKey = ({FlashcardSource source, String? lessonId});

class FlashcardBufferEntry {
  final String vocabularyId;
  final String result; // 'known' | 'unknown'

  const FlashcardBufferEntry({required this.vocabularyId, required this.result});
}

class FlashcardSessionState {
  final bool isLoading;
  final String? loadError;
  final List<FlashcardModel> deck;
  final Map<String, int> boxCounts;
  final int index;
  final List<FlashcardBufferEntry> buffer;
  final FlashcardBufferEntry? undoSlot;
  final bool isFlipped;
  final bool isSubmitting;
  final String? submitError;
  final ReviewSubmitResultModel? submitResult;

  const FlashcardSessionState({
    this.isLoading = true,
    this.loadError,
    this.deck = const <FlashcardModel>[],
    this.boxCounts = const <String, int>{},
    this.index = 0,
    this.buffer = const <FlashcardBufferEntry>[],
    this.undoSlot,
    this.isFlipped = false,
    this.isSubmitting = false,
    this.submitError,
    this.submitResult,
  });

  FlashcardModel? get currentCard => index < deck.length ? deck[index] : null;
  FlashcardModel? get nextCard => index + 1 < deck.length ? deck[index + 1] : null;
  FlashcardModel? get afterNextCard => index + 2 < deck.length ? deck[index + 2] : null;

  int get total => deck.length;
  int get progress => buffer.length;
  bool get canUndo => undoSlot != null;

  bool get isDeckEmpty => !isLoading && loadError == null && deck.isEmpty;
  bool get isSessionComplete => !isLoading && loadError == null && deck.isNotEmpty && index >= deck.length;

  FlashcardSessionState copyWith({
    bool? isLoading,
    String? loadError,
    bool clearLoadError = false,
    List<FlashcardModel>? deck,
    Map<String, int>? boxCounts,
    int? index,
    List<FlashcardBufferEntry>? buffer,
    FlashcardBufferEntry? undoSlot,
    bool clearUndoSlot = false,
    bool? isFlipped,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    ReviewSubmitResultModel? submitResult,
  }) {
    return FlashcardSessionState(
      isLoading: isLoading ?? this.isLoading,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      deck: deck ?? this.deck,
      boxCounts: boxCounts ?? this.boxCounts,
      index: index ?? this.index,
      buffer: buffer ?? this.buffer,
      undoSlot: clearUndoSlot ? null : (undoSlot ?? this.undoSlot),
      isFlipped: isFlipped ?? this.isFlipped,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitResult: submitResult ?? this.submitResult,
    );
  }
}

class FlashcardSessionNotifier extends StateNotifier<FlashcardSessionState> {
  final FlashcardRemoteDataSource _dataSource;

  FlashcardSessionNotifier(this._dataSource, FlashcardSource source, String? lessonId)
    : super(const FlashcardSessionState()) {
    _load(source, lessonId);
  }

  Future<void> _load(FlashcardSource source, String? lessonId) async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      final session = await _dataSource.getSession(source, lessonId: lessonId);
      state = state.copyWith(
        isLoading: false,
        clearLoadError: true,
        deck: session.cards,
        boxCounts: session.counts.boxes,
        index: 0,
        buffer: const <FlashcardBufferEntry>[],
        clearUndoSlot: true,
        isFlipped: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, loadError: error.toString());
    }
  }

  // FR-6: cham lat the xem nghia + vi du
  void flip() {
    if (state.currentCard == null) {
      return;
    }
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  // FR-7: vuot phai/trai hoac bam nut => tu danh gia da thuoc/chua thuoc
  void swipe(String result) {
    final FlashcardModel? card = state.currentCard;
    if (card == null) {
      return;
    }
    final entry = FlashcardBufferEntry(vocabularyId: card.vocabularyId, result: result);
    state = state.copyWith(
      buffer: <FlashcardBufferEntry>[...state.buffer, entry],
      undoSlot: entry,
      index: state.index + 1,
      isFlipped: false,
    );
  }

  // FR-8: chi hoan tac the vua vuot gan nhat, truoc khi vuot the ke tiep (GR-7)
  void undo() {
    if (state.undoSlot == null || state.buffer.isEmpty) {
      return;
    }
    final newBuffer = state.buffer.sublist(0, state.buffer.length - 1);
    state = state.copyWith(buffer: newBuffer, clearUndoSlot: true, index: state.index - 1, isFlipped: false);
  }

  // FR-3/FR-9: gui theo lo khi ket thuc phien hoac thoat giua chung (buffer hien co, khong goi API moi lan vuot)
  Future<bool> submit() async {
    if (state.buffer.isEmpty) {
      return true;
    }
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);
    try {
      final requests = state.buffer
          .map((e) => FlashcardReviewRequest(vocabularyId: e.vocabularyId, result: e.result))
          .toList();
      final result = await _dataSource.submitReviews(requests);
      state = state.copyWith(isSubmitting: false, clearSubmitError: true, submitResult: result);
      return true;
    } catch (error) {
      state = state.copyWith(isSubmitting: false, submitError: error.toString());
      return false;
    }
  }
}

final AutoDisposeStateNotifierProviderFamily<FlashcardSessionNotifier, FlashcardSessionState, FlashcardSessionKey>
flashcardSessionProvider =
    StateNotifierProvider.autoDispose
        .family<FlashcardSessionNotifier, FlashcardSessionState, FlashcardSessionKey>((
          Ref ref,
          FlashcardSessionKey key,
        ) {
          final FlashcardRemoteDataSource dataSource = ref.watch(flashcardRemoteDataSourceProvider);
          return FlashcardSessionNotifier(dataSource, key.source, key.lessonId);
        });
