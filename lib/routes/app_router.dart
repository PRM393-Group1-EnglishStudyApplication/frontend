import 'package:go_router/go_router.dart';

import '../features/auth/presentation/widgets/auth_gate.dart';
import '../features/courses/presentation/course_list_page.dart';
import '../features/courses/presentation/course_detail_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/units/presentation/unit_list_page.dart';
import '../features/lessons/presentation/lesson_list_page.dart';
import '../features/vocabulary/presentation/vocabulary_card_page.dart';
import 'app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const AuthGate(
          child: HomePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.courseList,
        builder: (context, state) => const CourseListPage(),
      ),
      GoRoute(
        path: AppRoutes.courseDetail,
        builder: (context, state) => CourseDetailPage(
          courseId: state.pathParameters['courseId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.unitList,
        builder: (context, state) => UnitListPage(
          courseId: state.pathParameters['courseId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.lessonList,
        builder: (context, state) => LessonListPage(
          unitId: state.pathParameters['unitId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.vocabularyCard,
        builder: (context, state) => VocabularyCardPage(
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
    ],
  );

  const AppRouter._();
}
