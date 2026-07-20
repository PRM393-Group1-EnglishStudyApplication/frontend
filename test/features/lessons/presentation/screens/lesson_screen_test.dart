import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/lessons/domain/entities/exercise_entities.dart';
import 'package:prm_frontend/features/lessons/domain/entities/lesson.dart';
import 'package:prm_frontend/features/lessons/presentation/providers/lessons_providers.dart';
import 'package:prm_frontend/features/lessons/presentation/screens/lesson_screen.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'CLERK_PUBLISHABLE_KEY=pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==\n'
          'API_BASE_URL=https://backend.example.test',
    );
  });

  testWidgets('clears a text answer before the next lesson exercise', (
    WidgetTester tester,
  ) async {
    const lesson = Lesson(
      id: 'lesson-1',
      title: 'Input reset',
      orderIndex: 1,
      xpReward: 10,
      unitId: 'unit-1',
    );
    const detail = LessonDetail(
      id: 'lesson-1',
      unitId: 'unit-1',
      title: 'Input reset',
      orderIndex: 1,
      xpReward: 10,
      vocabulary: <Vocabulary>[],
      exercises: <Exercise>[
        Exercise(
          id: 'exercise-1',
          lessonId: 'lesson-1',
          question: 'First lesson question',
          exerciseType: 'fill_blank',
          correctAnswer: 'first',
          options: <ExerciseOption>[],
        ),
        Exercise(
          id: 'exercise-2',
          lessonId: 'lesson-1',
          question: 'Second lesson question',
          exerciseType: 'translation',
          correctAnswer: 'second',
          options: <ExerciseOption>[],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          lessonDetailDataProvider.overrideWith(
            (Ref ref, String lessonId) async => detail,
          ),
        ],
        child: const MaterialApp(home: LessonScreen(lesson: lesson)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lesson-start-exercises-button')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump();
    await tester.tap(find.byKey(const Key('lesson-action-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('lesson-action-button')));
    await tester.pump();

    expect(find.text('Second lesson question'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '',
    );
  });
}
