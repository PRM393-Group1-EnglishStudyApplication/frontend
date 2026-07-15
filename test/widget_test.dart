import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/app/app.dart';

import 'mocks/mock_http_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock path_provider channel for production config initialization in widget tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );

    dotenv.loadFromString(
      envString: 'CLERK_PUBLISHABLE_KEY=pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==\nAPI_BASE_URL=https://backend-6i8r.onrender.com',
    );
  });

  testWidgets('App start renders SignInScreen when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PrmApp(
          httpService: MockHttpService(),
        ),
      ),
    );
    // Wait for async Clerk initialization to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Initial state is signed out, so it should render the sign-in screen
    expect(find.text('PRM Learning'), findsOneWidget);
  });
}
