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

  testWidgets('App shows an intro screen before the main experience', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PrmApp(
          httpService: MockHttpService(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Welcome to PRM Learning'), findsWidgets);
  });
}
