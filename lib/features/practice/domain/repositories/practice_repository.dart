import '../../../lessons/data/models/exercise_model.dart';

abstract class PracticeRepository {
  Future<List<ExerciseModel>> getPracticePack();
  Future<LessonSubmissionResult> submitPracticePack(List<Map<String, dynamic>> answers);
}
