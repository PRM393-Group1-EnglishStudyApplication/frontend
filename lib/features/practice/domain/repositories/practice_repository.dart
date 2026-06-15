import '../entities/wrong_word.dart';

abstract class PracticeRepository {
  Future<List<WrongWord>> getWrongWords();
  Future<int> getPracticeStreak();
  Future<int> getVocabularyCount();
  Future<int> getAccuracyPercentage();
}
