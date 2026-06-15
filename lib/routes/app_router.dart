import 'package:go_router/go_router.dart';

import '../features/auth/presentation/widgets/auth_gate.dart';
import '../features/courses/presentation/course_list_page.dart';
import '../features/courses/presentation/course_detail_page.dart';
import '../features/home/presentation/home_page.dart';
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
    ],
  );

  const AppRouter._();
}
