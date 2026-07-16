import '../entities/course.dart';
import '../entities/unit.dart';
import '../entities/lesson.dart';
import '../entities/exercise_entities.dart';

abstract class LessonsRepository {
  Future<List<Course>> getCourses();
  Future<List<Unit>> getUnits(String courseId);
  Future<List<Lesson>> getLessons(String unitId);
  Future<LessonDetail> getLessonDetail(String lessonId);
  Future<LessonSubmissionResult> submitLesson(
    String lessonId,
    List<Map<String, dynamic>> answers,
  );
}
