class AppRoutes {
  static const String home = '/';
  static const String courseList = '/courses';
  static const String courseDetail = '/courses/:courseId';
  static const String unitList = '/courses/:courseId/units';
  static const String lessonList = '/units/:unitId/lessons';

  const AppRoutes._();
}
