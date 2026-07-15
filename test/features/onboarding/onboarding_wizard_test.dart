import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/onboarding/presentation/screens/onboarding_wizard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_http_service.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString: 'CLERK_PUBLISHABLE_KEY=pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==\nAPI_BASE_URL=https://backend-6i8r.onrender.com',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('OnboardingWizard walkthrough (Zero Auth Quiz -> Celebration -> Registration)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ClerkAuth(
          config: TestClerkAuthConfig(
            publishableKey: 'pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==',
            httpService: const MockHttpService(),
          ),
          child: const MaterialApp(
            home: OnboardingWizard(),
          ),
        ),
      ),
    );

    // Initial load
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Purpose screen renders
    expect(find.text('What is your main purpose for learning?'), findsOneWidget);
    expect(find.text('✈️ Travel & Culture'), findsOneWidget);
    expect(find.text('💼 Career Growth'), findsOneWidget);

    // 1. Select Purpose
    await tester.tap(find.text('✈️ Travel & Culture'));
    await tester.pumpAndSettle();

    // Verify Level screen renders
    expect(find.text('Select your starting level'), findsOneWidget);
    expect(find.text('👶 I am brand new'), findsOneWidget);
    expect(find.text('🚀 I know some basics'), findsOneWidget);

    // 2. Select Level (Beginner)
    await tester.tap(find.text('👶 I am brand new'));
    await tester.pumpAndSettle();

    // Verify Quiz Question 1
    expect(find.text('Question 1 of 3'), findsOneWidget);
    expect(find.text("Chọn từ tiếng Anh có nghĩa là 'Xin chào':"), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);

    // 3. Answer Q1 correctly
    await tester.tap(find.text('Hello'));
    await tester.pump();
    // Advance transition timer (1 second)
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verify Quiz Question 2
    expect(find.text('Question 2 of 3'), findsOneWidget);
    expect(find.text("Từ nào dưới đây có nghĩa là 'Cảm ơn'?"), findsOneWidget);
    expect(find.text('Thank you'), findsOneWidget);

    // 4. Answer Q2 correctly
    await tester.tap(find.text('Thank you'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verify Quiz Question 3
    expect(find.text('Question 3 of 3'), findsOneWidget);
    expect(find.text("Hoàn thành câu sau: 'How ___ you?' (Bạn khỏe không?)"), findsOneWidget);
    expect(find.text('are'), findsOneWidget);

    // 5. Answer Q3 correctly
    await tester.tap(find.text('are'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verify Celebration Screen
    expect(find.text('Micro-lesson Complete!'), findsOneWidget);
    expect(find.text('You answered 3 of 3 questions correctly. Let\'s lock in your achievements.'), findsOneWidget);
    expect(find.text('+150'), findsOneWidget);
    expect(find.text('XP Unlocked'), findsOneWidget);

    // 6. Click Continue to Registration
    await tester.tap(find.text('Continue to Lock In Progress'));
    await tester.pumpAndSettle();

    // Verify Registration Screen with Clerk
    expect(find.text('Create a free account to lock in your 150 XP and start Unit 1.'), findsOneWidget);
    expect(find.byType(ClerkAuthentication), findsOneWidget);
  });
}
