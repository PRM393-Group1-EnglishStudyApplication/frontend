import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/flashcards/data/models/flashcard_model.dart';
import 'package:prm_frontend/features/flashcards/data/models/review_result_model.dart';

void main() {
  group('FlashcardModel.fromJson', () {
    test('parses a full card', () {
      final model = FlashcardModel.fromJson(<String, dynamic>{
        'vocabulary_id': '665f...',
        'word': 'went',
        'pronunciation': '/went/',
        'meaning': 'đã đi (quá khứ của go)',
        'example_sentence': 'I went to school yesterday.',
        'box': 2,
        'is_new': false,
      });

      expect(model.vocabularyId, '665f...');
      expect(model.word, 'went');
      expect(model.pronunciation, '/went/');
      expect(model.meaning, 'đã đi (quá khứ của go)');
      expect(model.exampleSentence, 'I went to school yesterday.');
      expect(model.box, 2);
      expect(model.isNew, false);
    });

    test('dien gia tri mac dinh khi field thieu', () {
      final model = FlashcardModel.fromJson(<String, dynamic>{});
      expect(model.vocabularyId, '');
      expect(model.word, '');
      expect(model.pronunciation, null);
      expect(model.meaning, '');
      expect(model.exampleSentence, null);
      expect(model.box, 1);
      expect(model.isNew, false);
    });
  });

  group('FlashcardSessionModel.fromJson', () {
    test('parses source, cards va counts', () {
      final model = FlashcardSessionModel.fromJson(<String, dynamic>{
        'source': 'due',
        'cards': [
          {'vocabulary_id': 'a', 'word': 'hello', 'meaning': 'xin chao', 'box': 1, 'is_new': true},
        ],
        'counts': {
          'due': 12,
          'new': 5,
          'boxes': {'1': 4, '2': 8, '3': 15, '4': 6, '5': 30},
        },
      });

      expect(model.source, 'due');
      expect(model.cards.length, 1);
      expect(model.cards.first.word, 'hello');
      expect(model.counts.due, 12);
      expect(model.counts.newCount, 5);
      expect(model.counts.boxes['3'], 15);
    });

    test('mang cards rong khi khong co the nao', () {
      final model = FlashcardSessionModel.fromJson(<String, dynamic>{
        'source': 'favorites',
        'cards': <dynamic>[],
        'counts': {'due': 0, 'new': 0, 'boxes': <String, dynamic>{}},
      });

      expect(model.cards, isEmpty);
      expect(model.counts.due, 0);
    });
  });

  group('ReviewSubmitResultModel.fromJson', () {
    test('parses updated list, earned_xp, daily_xp_remaining', () {
      final model = ReviewSubmitResultModel.fromJson(<String, dynamic>{
        'updated': [
          {'vocabulary_id': '665f...', 'box': 3, 'next_review_at': '2026-07-19T04:00:00Z'},
        ],
        'earned_xp': 5,
        'daily_xp_remaining': 15,
      });

      expect(model.updated.length, 1);
      expect(model.updated.first.vocabularyId, '665f...');
      expect(model.updated.first.box, 3);
      expect(model.updated.first.nextReviewAt, DateTime.parse('2026-07-19T04:00:00Z'));
      expect(model.earnedXp, 5);
      expect(model.dailyXpRemaining, 15);
    });
  });
}
