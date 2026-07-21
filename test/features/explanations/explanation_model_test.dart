import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/explanations/data/models/explanation_model.dart';

void main() {
  group('ExplanationModel.fromJson', () {
    test('parses a full backend response', () {
      final model = ExplanationModel.fromJson(<String, dynamic>{
        'exercise_id': '665f0c1234567890abcdef01',
        'user_answer': 'I goed to school',
        'correct_answer': 'I went to school',
        'explanation': <String, dynamic>{
          'why_wrong': "Ban da dung -ed cho dong tu bat quy tac 'go'.",
          'why_correct': "'go' o thi qua khu don la 'went'.",
          'tip': 'go -> went -> gone',
        },
        'cached': false,
      });

      expect(model.exerciseId, '665f0c1234567890abcdef01');
      expect(model.userAnswer, 'I goed to school');
      expect(model.correctAnswer, 'I went to school');
      expect(model.whyWrong, "Ban da dung -ed cho dong tu bat quy tac 'go'.");
      expect(model.whyCorrect, "'go' o thi qua khu don la 'went'.");
      expect(model.tip, 'go -> went -> gone');
      expect(model.cached, false);
    });

    test('parses a cache-hit response', () {
      final model = ExplanationModel.fromJson(<String, dynamic>{
        'exercise_id': 'ex1',
        'user_answer': 'goed',
        'correct_answer': 'went',
        'explanation': <String, dynamic>{
          'why_wrong': 'a',
          'why_correct': 'b',
          'tip': 'c',
        },
        'cached': true,
      });

      expect(model.cached, true);
    });

    test('dien gia tri mac dinh khi thieu field explanation', () {
      final model = ExplanationModel.fromJson(<String, dynamic>{
        'exercise_id': 'ex1',
        'user_answer': 'goed',
        'correct_answer': 'went',
        'cached': false,
      });

      expect(model.whyWrong, '');
      expect(model.whyCorrect, '');
      expect(model.tip, '');
    });

    test('dien gia tri mac dinh khi cac field khac bi thieu/null', () {
      final model = ExplanationModel.fromJson(<String, dynamic>{});

      expect(model.exerciseId, '');
      expect(model.userAnswer, '');
      expect(model.correctAnswer, '');
      expect(model.whyWrong, '');
      expect(model.whyCorrect, '');
      expect(model.tip, '');
      expect(model.cached, false);
    });
  });
}
