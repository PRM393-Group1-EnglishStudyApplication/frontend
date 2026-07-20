import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/lessons/domain/entities/exercise_entities.dart';
import 'package:prm_frontend/features/lessons/presentation/widgets/matching_exercise.dart';

void main() {
  testWidgets('keeps both matching tiles aligned on narrow screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const options = <ExerciseOption>[
      ExerciseOption(
        id: '1',
        exerciseId: 'matching',
        optionText:
            'note-taking::việc ghi chép thông tin quan trọng trong bài giảng',
        isCorrect: true,
      ),
      ExerciseOption(
        id: '2',
        exerciseId: 'matching',
        optionText: 'clarification::sự làm rõ hoặc lời giải thích rõ ràng hơn',
        isCorrect: true,
      ),
      ExerciseOption(
        id: '3',
        exerciseId: 'matching',
        optionText: 'delve into::đi sâu vào một chủ đề để nghiên cứu kỹ',
        isCorrect: true,
      ),
      ExerciseOption(
        id: '4',
        exerciseId: 'matching',
        optionText: 'comprehension::khả năng hiểu đầy đủ điều đang được nói',
        isCorrect: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MatchingExercise(
                options: options,
                enabled: true,
                onAnswerChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    for (var index = 0; index < options.length; index++) {
      final left = tester.getRect(
        find.byKey(ValueKey<String>('matching-left-$index')),
      );
      final right = tester.getRect(
        find.byKey(ValueKey<String>('matching-right-$index')),
      );

      expect(left.top, right.top);
      expect(left.bottom, right.bottom);
      expect(left.height, greaterThanOrEqualTo(60));
    }

    expect(tester.takeException(), isNull);
  });
}
