import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/lessons_remote_data_source.dart';
import '../../data/repositories/lessons_repository_impl.dart';
import '../../domain/repositories/lessons_repository.dart';
import '../../data/models/course_model.dart';
import '../../data/models/unit_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/exercise_model.dart';

final Provider<LessonsRemoteDataSource> lessonsRemoteDataSourceProvider =
    Provider<LessonsRemoteDataSource>((Ref ref) {
  final dio = ref.watch(authDioProvider);
  return LessonsRemoteDataSourceImpl(dio);
});

final Provider<LessonsRepository> lessonsRepositoryProvider =
    Provider<LessonsRepository>((Ref ref) {
  final remoteDataSource = ref.watch(lessonsRemoteDataSourceProvider);
  return LessonsRepositoryImpl(remoteDataSource);
});

final FutureProvider<List<CourseModel>> coursesDataProvider =
    FutureProvider<List<CourseModel>>((Ref ref) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  return repository.getCourses();
});

final FutureProviderFamily<List<UnitModel>, String> unitsDataProvider =
    FutureProvider.family<List<UnitModel>, String>((Ref ref, String courseId) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  return repository.getUnits(courseId);
});

final FutureProviderFamily<List<LessonModel>, String> lessonsDataProvider =
    FutureProvider.family<List<LessonModel>, String>((Ref ref, String unitId) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  return repository.getLessons(unitId);
});

final FutureProviderFamily<LessonDetailModel, String> lessonDetailDataProvider =
    FutureProvider.family<LessonDetailModel, String>((Ref ref, String lessonId) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  return repository.getLessonDetail(lessonId);
});
