import '../../data/models/course_model.dart';
import '../../data/models/unit_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/exercise_model.dart';

abstract class LessonsRepository {
  Future<List<CourseModel>> getCourses();
  Future<List<UnitModel>> getUnits(String courseId);
  Future<List<LessonModel>> getLessons(String unitId);
  Future<LessonDetailModel> getLessonDetail(String lessonId);
  Future<LessonSubmissionResult> submitLesson(String lessonId, List<Map<String, dynamic>> answers);
}
