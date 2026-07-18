import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/flashcards/data/datasources/flashcard_remote_data_source.dart';
import 'package:prm_frontend/features/flashcards/data/models/flashcard_model.dart';
import 'package:prm_frontend/features/flashcards/data/models/review_result_model.dart';
import 'package:prm_frontend/features/flashcards/presentation/providers/flashcard_providers.dart';

class FakeFlashcardRemoteDataSource implements FlashcardRemoteDataSource {
  FlashcardSessionModel? sessionToReturn;
  Object? sessionError;
  ReviewSubmitResultModel? reviewResultToReturn;
  Object? reviewError;
  List<FlashcardReviewRequest>? lastSubmittedReviews;

  @override
  Future<FlashcardSessionModel> getSession(FlashcardSource source, {String? lessonId}) async {
    if (sessionError != null) {
      throw sessionError!;
    }
    return sessionToReturn!;
  }

  @override
  Future<ReviewSubmitResultModel> submitReviews(List<FlashcardReviewRequest> reviews) async {
    lastSubmittedReviews = reviews;
    if (reviewError != null) {
      throw reviewError!;
    }
    return reviewResultToReturn!;
  }

  @override
  Future<String> getTtsAudioUrl(String text, {String lang = 'en'}) async => 'https://tts.example.com/audio.mp3';
}

FlashcardModel _card(String id) => FlashcardModel(
  vocabularyId: id,
  word: 'word-$id',
  meaning: 'nghia-$id',
  box: 1,
  isNew: true,
);

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeFlashcardRemoteDataSource dataSource;

  setUp(() {
    dataSource = FakeFlashcardRemoteDataSource();
  });

  group('FlashcardSessionNotifier - tai phien', () {
    test('tai thanh cong -> deck va boxCounts duoc dien', () async {
      dataSource.sessionToReturn = FlashcardSessionModel(
        source: 'due',
        cards: [_card('a'), _card('b')],
        counts: const FlashcardCountsModel(due: 2, newCount: 0, boxes: {'1': 2}),
      );

      final notifier = FlashcardSessionNotifier(dataSource, FlashcardSource.due, null);
      await _flushMicrotasks();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.loadError, null);
      expect(notifier.state.deck.length, 2);
      expect(notifier.state.boxCounts['1'], 2);
      expect(notifier.state.isDeckEmpty, false);
      notifier.dispose();
    });

    test('tai loi -> loadError duoc set', () async {
      dataSource.sessionError = Exception('network error');

      final notifier = FlashcardSessionNotifier(dataSource, FlashcardSource.due, null);
      await _flushMicrotasks();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.loadError, contains('network error'));
      notifier.dispose();
    });

    test('deck rong -> isDeckEmpty true (FR-11)', () async {
      dataSource.sessionToReturn = const FlashcardSessionModel(
        source: 'due',
        cards: [],
        counts: FlashcardCountsModel(due: 0, newCount: 0, boxes: {}),
      );

      final notifier = FlashcardSessionNotifier(dataSource, FlashcardSource.due, null);
      await _flushMicrotasks();

      expect(notifier.state.isDeckEmpty, true);
      expect(notifier.state.isSessionComplete, false);
      notifier.dispose();
    });
  });

  group('FlashcardSessionNotifier - flip/swipe/undo', () {
    late FlashcardSessionNotifier notifier;

    setUp(() async {
      dataSource.sessionToReturn = FlashcardSessionModel(
        source: 'due',
        cards: [_card('a'), _card('b'), _card('c')],
        counts: const FlashcardCountsModel(due: 3, newCount: 0, boxes: {}),
      );
      notifier = FlashcardSessionNotifier(dataSource, FlashcardSource.due, null);
      await _flushMicrotasks();
    });

    tearDown(() => notifier.dispose());

    test('flip() dao trang thai isFlipped cua the hien tai', () {
      expect(notifier.state.isFlipped, false);
      notifier.flip();
      expect(notifier.state.isFlipped, true);
      notifier.flip();
      expect(notifier.state.isFlipped, false);
    });

    test('swipe() them vao buffer, dat undoSlot, tang index, reset isFlipped', () {
      notifier.flip();
      notifier.swipe('known');

      expect(notifier.state.index, 1);
      expect(notifier.state.buffer.length, 1);
      expect(notifier.state.buffer.first.vocabularyId, 'a');
      expect(notifier.state.buffer.first.result, 'known');
      expect(notifier.state.canUndo, true);
      expect(notifier.state.isFlipped, false);
      expect(notifier.state.progress, 1);
    });

    test('undo() hoan tac dung the vua vuot gan nhat (GR-7)', () {
      notifier.swipe('unknown'); // vuot the 'a'
      notifier.undo();

      expect(notifier.state.index, 0);
      expect(notifier.state.buffer, isEmpty);
      expect(notifier.state.canUndo, false);
      expect(notifier.state.currentCard?.vocabularyId, 'a');
    });

    test('undo roi vuot lai the cu voi ket qua khac -> chi 1 ban ghi ket qua cuoi', () {
      notifier.swipe('unknown');
      notifier.undo();
      notifier.swipe('known');

      expect(notifier.state.buffer.length, 1);
      expect(notifier.state.buffer.first.result, 'known');
    });

    test('undo() khong lam gi khi khong co undoSlot', () {
      notifier.undo();
      expect(notifier.state.index, 0);
      expect(notifier.state.buffer, isEmpty);
    });

    test('undo() chi ap dung cho the vua vuot gan nhat - vuot 2 the roi undo chi hoan the thu 2', () {
      notifier.swipe('known'); // 'a'
      notifier.swipe('unknown'); // 'b'
      notifier.undo();

      expect(notifier.state.index, 1);
      expect(notifier.state.buffer.length, 1);
      expect(notifier.state.buffer.first.vocabularyId, 'a');
      expect(notifier.state.currentCard?.vocabularyId, 'b');
    });

    test('vuot het deck -> isSessionComplete true', () {
      notifier.swipe('known');
      notifier.swipe('known');
      notifier.swipe('known');

      expect(notifier.state.isSessionComplete, true);
      expect(notifier.state.currentCard, null);
    });
  });

  group('FlashcardSessionNotifier - submit', () {
    test('buffer rong -> tra ve true, khong goi datasource', () async {
      dataSource.sessionToReturn = const FlashcardSessionModel(
        source: 'due',
        cards: [],
        counts: FlashcardCountsModel(due: 0, newCount: 0, boxes: {}),
      );
      final notifier = FlashcardSessionNotifier(dataSource, FlashcardSource.due, null);
      await _flushMicrotasks();

      final ok = await notifier.submit();

      expect(ok, true);
      expect(dataSource.lastSubmittedReviews, null);
      notifier.dispose();
    });

    test('gui buffer thanh cong -> submitResult duoc set, dung dung request', () async {
      dataSource.sessionToReturn = FlashcardSessionModel(
        source: 'due',
        cards: [_card('a'), _card('b')],
        counts: const FlashcardCountsModel(due: 2, newCount: 0, boxes: {}),
      );
      final notifier = FlashcardSessionNotifier(dataSource, FlashcardSource.due, null);
      await _flushMicrotasks();

      notifier.swipe('known');
      notifier.swipe('unknown');

      dataSource.reviewResultToReturn = const ReviewSubmitResultModel(
        updated: [],
        earnedXp: 5,
        dailyXpRemaining: 15,
      );

      final ok = await notifier.submit();

      expect(ok, true);
      expect(notifier.state.submitResult?.earnedXp, 5);
      expect(dataSource.lastSubmittedReviews?.length, 2);
      expect(dataSource.lastSubmittedReviews?[0].vocabularyId, 'a');
      expect(dataSource.lastSubmittedReviews?[0].result, 'known');
      notifier.dispose();
    });

    test('gui buffer loi -> submitError duoc set, tra ve false', () async {
      dataSource.sessionToReturn = FlashcardSessionModel(
        source: 'due',
        cards: [_card('a')],
        counts: const FlashcardCountsModel(due: 1, newCount: 0, boxes: {}),
      );
      final notifier = FlashcardSessionNotifier(dataSource, FlashcardSource.due, null);
      await _flushMicrotasks();

      notifier.swipe('known');
      dataSource.reviewError = Exception('Bạn đã dùng hết lượt giải thích');

      final ok = await notifier.submit();

      expect(ok, false);
      expect(notifier.state.submitError, contains('Bạn đã dùng hết lượt giải thích'));
      notifier.dispose();
    });
  });
}
