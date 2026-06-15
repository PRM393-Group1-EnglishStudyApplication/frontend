import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/auth/domain/entities/app_user.dart';
import 'package:prm_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:prm_frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:prm_frontend/features/home/presentation/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/mock_http_service.dart';

class FakeAuthRepository implements AuthRepository {
  AppUser? user;
  Object? exception;
  int callCount = 0;

  @override
  Future<AppUser> getCurrentUser() async {
    callCount++;
    if (exception != null) {
      throw exception!;
    }
    if (user != null) {
      return user!;
    }
    throw Exception('No fake user provided');
  }
}

void main() {
  const testUser = AppUser(
    id: 'user_123',
    email: 'jane.doe@example.com',
    fullName: 'Jane Doe',
    avatarUrl: '',
    totalXp: 450,
    currentLevel: 'intermediate',
    streakCount: 5,
  );

  late FakeAuthRepository fakeAuthRepository;

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'CLERK_PUBLISHABLE_KEY=pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==\nAPI_BASE_URL=https://backend-6i8r.onrender.com',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    fakeAuthRepository = FakeAuthRepository()..user = testUser;
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        clerkTokenProvider.overrideWith((ref) => 'fake_token'),
      ],
      child: ClerkAuth(
        config: TestClerkAuthConfig(
          publishableKey: 'pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==',
          httpService: const MockHttpService(clientResponse: janeDoeClientResponse),
        ),
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );
  }

  testWidgets('HomePage renders NavigationBar with four tabs', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    // Wait for async Clerk initialization to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify NavigationBar renders with 4 destinations
    final navBarFinder = find.byType(NavigationBar);
    expect(navBarFinder, findsOneWidget);

    final navigationBar = tester.widget<NavigationBar>(navBarFinder);
    expect(navigationBar.destinations.length, 4);

    // Verify tab labels
    expect(find.text('Learn'), findsWidgets);
    expect(find.text('Leaderboard'), findsWidgets);
    expect(find.text('Quests'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('HomePage initial state shows Learn tab content', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify language / course title
    expect(find.text('Vietnamese'), findsOneWidget);

    // Verify stats pills values
    expect(find.text('7'), findsOneWidget); // Streak
    expect(find.text('320'), findsOneWidget); // Diamonds
    expect(find.text('5'), findsOneWidget); // Hearts

    // Verify progress card details
    expect(find.text('Unit 1'), findsOneWidget);
    expect(find.text('Basics – Greetings & Numbers'), findsOneWidget);
    expect(find.text('2 of 5 lessons completed'), findsOneWidget);

    // Scroll down to bring daily quests card into view
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pump();

    // Verify daily quests card
    expect(find.text('Daily Quests'), findsOneWidget);
    expect(find.text('Earn 10 XP'), findsOneWidget);
    expect(find.text('Complete 1 lesson'), findsOneWidget);
  });

  testWidgets('Tapping Leaderboard tab displays placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the Leaderboard tab
    await tester.tap(find.text('Leaderboard'));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify placeholder text is shown
    expect(find.text('Leaderboard'), findsWidgets);
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('Tapping Quests tab displays placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the Quests tab
    await tester.tap(find.text('Quests'));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify placeholder text is shown
    expect(find.text('Quests'), findsWidgets);
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('Tapping Profile tab displays profile card and sign-out button', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify user details
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane.doe@example.com'), findsOneWidget);

    // Verify sign out button is visible
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
