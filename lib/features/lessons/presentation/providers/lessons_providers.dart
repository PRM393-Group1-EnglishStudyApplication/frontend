import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/lessons_remote_data_source.dart';
import '../../data/repositories/lessons_repository_impl.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/exercise_entities.dart';
import '../../domain/repositories/lessons_repository.dart';
import '../../domain/usecases/submit_lesson.dart';

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

final Provider<SubmitLesson> submitLessonProvider = Provider<SubmitLesson>((Ref ref) {
  final repository = ref.watch(lessonsRepositoryProvider);
  return SubmitLesson(repository);
});

final FutureProvider<List<Course>> coursesDataProvider =
    FutureProvider<List<Course>>((Ref ref) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  return repository.getCourses();
});

final FutureProviderFamily<List<Unit>, String> unitsDataProvider =
    FutureProvider.family<List<Unit>, String>((Ref ref, String courseId) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  return repository.getUnits(courseId);
});

final FutureProviderFamily<List<Lesson>, String> lessonsDataProvider =
    FutureProvider.family<List<Lesson>, String>((Ref ref, String unitId) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  return repository.getLessons(unitId);
});

// autoDispose de moi lan mo bai hoc lay mot bo cau hoi ngau nhien moi tu server.
final AutoDisposeFutureProviderFamily<LessonDetail, String> lessonDetailDataProvider =
    FutureProvider.autoDispose.family<LessonDetail, String>((Ref ref, String lessonId) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  return repository.getLessonDetail(lessonId);
});
