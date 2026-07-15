import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/auth/presentation/screens/sign_in_screen.dart';

import '../../mocks/mock_http_service.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString: 'CLERK_PUBLISHABLE_KEY=pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==\nAPI_BASE_URL=https://backend-6i8r.onrender.com',
    );
  });

  testWidgets('SignInScreen renders branding and ClerkAuthentication', (WidgetTester tester) async {
    await tester.pumpWidget(
      ClerkAuth(
        config: TestClerkAuthConfig(
          publishableKey: 'pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==',
          httpService: const MockHttpService(),
        ),
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      ),
    );
    // Wait for async Clerk initialization to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify app name/branding renders
    expect(find.text('PRM Learning'), findsOneWidget);
    expect(
      find.text('Unlock your potential. Learn, practice, and master skills at your own pace.'),
      findsOneWidget,
    );

    // Verify built-in ClerkAuthentication is embedded
    expect(find.byType(ClerkAuthentication), findsOneWidget);
  });
}
