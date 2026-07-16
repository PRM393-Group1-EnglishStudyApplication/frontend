import '../../../lessons/domain/entities/exercise_entities.dart';

abstract class PracticeRepository {
  Future<List<Exercise>> getPracticePack();
  Future<LessonSubmissionResult> submitPracticePack(List<Map<String, dynamic>> answers);
}
