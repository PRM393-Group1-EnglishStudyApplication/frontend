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
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('HomePage initial state shows Home tab with greeting and summary', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify greeting text
    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);

    // Verify summary rows
    expect(find.text('Current Level'), findsOneWidget);
    expect(find.text('INTERMEDIATE'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('5 Days'), findsOneWidget);
    expect(find.text('Total XP'), findsOneWidget);
    expect(find.text('450 XP'), findsOneWidget);
  });

  testWidgets('Tapping Courses tab displays simple course placeholders', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the Courses tab
    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();

    // Verify AppBar title changed
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Courses')), findsOneWidget);

    // Verify some course placeholders are present
    expect(find.text('Introduction to Mobile Programming'), findsOneWidget);
    expect(find.text('Learn Flutter & Dart basics'), findsOneWidget);
    expect(find.text('Advanced Flutter UI & Animations'), findsOneWidget);
  });

  testWidgets('Tapping Progress tab displays current user statistics cards', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the Progress tab
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    // Verify AppBar title changed
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Progress')), findsOneWidget);

    // Verify Stats Overview title
    expect(find.text('Stats Overview'), findsOneWidget);

    // Verify card content
    expect(find.text('Level'), findsOneWidget);
    expect(find.text('INTERMEDIATE'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('5 Days'), findsOneWidget);
    expect(find.text('Total XP'), findsOneWidget);
    expect(find.text('450 XP'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('Tapping Profile tab displays profile card and sync/sign-out buttons', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify AppBar title changed
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Profile')), findsOneWidget);

    // Verify user details
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane.doe@example.com'), findsOneWidget);

    // Verify buttons are visible
    expect(find.text('Sync with Backend'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);

    // Tap Sync with Backend and verify mock call count
    final initialCallCount = fakeAuthRepository.callCount;
    await tester.tap(find.text('Sync with Backend'));
    await tester.pumpAndSettle();
    expect(fakeAuthRepository.callCount, initialCallCount + 1);
  });
}
