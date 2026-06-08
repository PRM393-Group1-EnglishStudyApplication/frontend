import 'package:flutter_test/flutter_test.dart';

import 'package:prm_frontend/app/app.dart';

void main() {
  testWidgets('Render home page', (WidgetTester tester) async {
    await tester.pumpWidget(const PrmApp());

    expect(find.text('PRM Frontend Home'), findsOneWidget);
    expect(
      find.text('Flutter FE is ready. Tap button to test API call.'),
      findsOneWidget,
    );
  });
}
