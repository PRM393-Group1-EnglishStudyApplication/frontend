import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/lessons/domain/entities/course.dart';
import 'package:prm_frontend/features/lessons/presentation/providers/lessons_providers.dart';
import 'package:prm_frontend/features/lessons/presentation/screens/course_path_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'CLERK_PUBLISHABLE_KEY=pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==\n'
          'API_BASE_URL=https://backend.example.test',
    );
  });

  testWidgets(
    'does not show the empty course state while courses are loading',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final courses = Completer<List<Course>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            coursesDataProvider.overrideWith((Ref ref) => courses.future),
          ],
          child: const MaterialApp(home: CoursePathScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsNothing);

      courses.complete(<Course>[]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    },
  );
}
