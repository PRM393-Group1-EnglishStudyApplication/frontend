import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:prm_frontend/features/hearts/domain/entities/heart_status.dart';
import 'package:prm_frontend/features/hearts/domain/repositories/heart_repository.dart';
import 'package:prm_frontend/features/hearts/presentation/providers/heart_providers.dart';
import 'package:prm_frontend/features/lessons/domain/entities/exercise_entities.dart';
import 'package:prm_frontend/features/practice/domain/repositories/practice_repository.dart';
import 'package:prm_frontend/features/practice/presentation/providers/practice_providers.dart';
import 'package:prm_frontend/features/practice/presentation/screens/practice_pack_screen.dart';

class FakePracticeRepository implements PracticeRepository {
  FakePracticeRepository(this.pack);

  final WrongAnswerPack pack;
  List<Map<String, dynamic>>? submittedAnswers;

  @override
  Future<List<Exercise>> getPracticePack() async => pack.items;

  @override
  Future<WrongAnswerPack> getWrongAnswerPack() async => pack;

  @override
  Future<LessonSubmissionResult> submitPracticePack(
    List<Map<String, dynamic>> answers,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<WrongAnswerReviewResult> submitWrongAnswerReview(
    List<Map<String, dynamic>> answers,
  ) async {
    submittedAnswers = answers;
    return const WrongAnswerReviewResult(
      totalQuestions: 1,
      correctAnswers: 0,
      score: 0,
      remainingWrongAnswers: 1,
    );
  }
}

class FakeHeartRepository implements HeartRepository {
  const FakeHeartRepository();

  @override
  Future<HeartStatus> getMyHearts() async {
    return const HeartStatus(userId: 'user-1', currentHearts: 5, maxHearts: 15);
  }

  @override
  Future<HeartStatus> refillHearts() => getMyHearts();
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'CLERK_PUBLISHABLE_KEY=pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==\n'
          'API_BASE_URL=https://backend.example.test',
    );
  });

  testWidgets('clears a text answer before showing the next exercise', (
    WidgetTester tester,
  ) async {
    const exercises = <Exercise>[
      Exercise(
        id: 'exercise-1',
        lessonId: 'lesson-1',
        question: 'First question',
        exerciseType: 'fill_blank',
        correctAnswer: 'first',
        options: <ExerciseOption>[],
      ),
      Exercise(
        id: 'exercise-2',
        lessonId: 'lesson-1',
        question: 'Second question',
        exerciseType: 'translation',
        correctAnswer: 'second',
        options: <ExerciseOption>[],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          practicePackProvider.overrideWith((Ref ref) async => exercises),
        ],
        child: const MaterialApp(home: PracticePackScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump();
    const actionButton = Key('practice-action-button');
    await tester.tap(find.byKey(actionButton));
    await tester.pump();
    await tester.tap(find.byKey(actionButton));
    await tester.pump();

    expect(find.text('Second question'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '',
    );
  });

  testWidgets('wrong-answer review submits without deducting a heart', (
    WidgetTester tester,
  ) async {
    const exercise = Exercise(
      id: 'wrong-1',
      lessonId: 'lesson-1',
      question: 'Review this answer',
      exerciseType: 'fill_blank',
      correctAnswer: 'correct',
      options: <ExerciseOption>[],
    );
    final repository = FakePracticeRepository(
      const WrongAnswerPack(items: <Exercise>[exercise], total: 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          practiceRepositoryProvider.overrideWithValue(repository),
          heartRepositoryProvider.overrideWithValue(
            const FakeHeartRepository(),
          ),
          clerkTokenProvider.overrideWith((Ref ref) => 'token'),
        ],
        child: const MaterialApp(home: PracticePackScreen.wrongAnswers()),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PracticePackScreen)),
    );
    expect(container.read(heartProvider).hearts?.currentHearts, 5);

    await tester.enterText(find.byType(TextField), 'still wrong');
    await tester.pump();
    await tester.tap(find.byKey(const Key('practice-action-button')));
    await tester.pump();

    expect(container.read(heartProvider).hearts?.currentHearts, 5);

    await tester.tap(find.byKey(const Key('practice-action-button')));
    await tester.pumpAndSettle();

    expect(repository.submittedAnswers, <Map<String, dynamic>>[
      <String, dynamic>{'exerciseId': 'wrong-1', 'userAnswer': 'still wrong'},
    ]);
    expect(container.read(heartProvider).hearts?.currentHearts, 5);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('1 câu'), findsOneWidget);
  });
}
