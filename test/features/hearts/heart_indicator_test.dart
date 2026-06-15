import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:prm_frontend/features/hearts/domain/entities/heart_status.dart';
import 'package:prm_frontend/features/hearts/domain/repositories/heart_repository.dart';
import 'package:prm_frontend/features/hearts/presentation/providers/heart_providers.dart';
import 'package:prm_frontend/features/hearts/presentation/widgets/heart_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeHeartRepository implements HeartRepository {
  HeartStatus hearts;

  FakeHeartRepository(this.hearts);

  @override
  Future<HeartStatus> getMyHearts() async => hearts;

  @override
  Future<HeartStatus> refillHearts() async {
    hearts = hearts.copyWith(currentHearts: hearts.maxHearts);
    return hearts;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows heart count and opens refill details', (
    WidgetTester tester,
  ) async {
    final FakeHeartRepository repository = FakeHeartRepository(
      const HeartStatus(userId: 'user_123', currentHearts: 3, maxHearts: 5),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          clerkTokenProvider.overrideWith((Ref ref) => 'token'),
          heartRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const <Widget>[HeartIndicator()]),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('heart_indicator_button')));
    await tester.pumpAndSettle();

    expect(find.text('Your hearts'), findsOneWidget);
    expect(find.text('Full refill in'), findsOneWidget);
    expect(find.byKey(const Key('refill_hearts_button')), findsOneWidget);
  });
}
