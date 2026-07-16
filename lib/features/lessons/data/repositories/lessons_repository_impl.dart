import '../../domain/entities/course.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/exercise_entities.dart';
import '../../domain/repositories/lessons_repository.dart';
import '../datasources/lessons_remote_data_source.dart';

class LessonsRepositoryImpl implements LessonsRepository {
  final LessonsRemoteDataSource _remoteDataSource;

  LessonsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Course>> getCourses() => _remoteDataSource.getCourses();

  @override
  Future<List<Unit>> getUnits(String courseId) => _remoteDataSource.getUnits(courseId);

  @override
  Future<List<Lesson>> getLessons(String unitId) => _remoteDataSource.getLessons(unitId);

  @override
  Future<LessonDetail> getLessonDetail(String lessonId) => _remoteDataSource.getLessonDetail(lessonId);

  @override
  Future<LessonSubmissionResult> submitLesson(
    String lessonId,
    List<Map<String, dynamic>> answers,
  ) =>
      _remoteDataSource.submitLesson(lessonId, answers);
}
