import '../entities/exercise_entities.dart';
import '../repositories/lessons_repository.dart';

class SubmitLesson {
  final LessonsRepository _repository;

  const SubmitLesson(this._repository);

  Future<LessonSubmissionResult> call(
    String lessonId,
    List<Map<String, dynamic>> answers,
  ) {
    return _repository.submitLesson(lessonId, answers);
  }
}
