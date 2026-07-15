import '../../domain/repositories/lessons_repository.dart';
import '../datasources/lessons_remote_data_source.dart';
import '../models/course_model.dart';
import '../models/unit_model.dart';
import '../models/lesson_model.dart';
import '../models/exercise_model.dart';

class LessonsRepositoryImpl implements LessonsRepository {
  final LessonsRemoteDataSource _remoteDataSource;

  LessonsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<CourseModel>> getCourses() => _remoteDataSource.getCourses();

  @override
  Future<List<UnitModel>> getUnits(String courseId) => _remoteDataSource.getUnits(courseId);

  @override
  Future<List<LessonModel>> getLessons(String unitId) => _remoteDataSource.getLessons(unitId);

  @override
  Future<LessonDetailModel> getLessonDetail(String lessonId) => _remoteDataSource.getLessonDetail(lessonId);

  @override
  Future<LessonSubmissionResult> submitLesson(String lessonId, List<Map<String, dynamic>> answers) =>
      _remoteDataSource.submitLesson(lessonId, answers);
}
