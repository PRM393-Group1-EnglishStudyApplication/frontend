import '../../domain/entities/wrong_word.dart';
import '../../domain/repositories/practice_repository.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  @override
  Future<List<WrongWord>> getWrongWords() async {
    // Return mock data matching Google Stitch screen 7613553ce5f44a378e791d4225782dcb
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const [
      WrongWord(
        word: 'Subtle',
        level: 'B2',
        definition: 'Tinh tế',
        mistakeExplanation: 'Nhầm lẫn cách phát âm /sʌt.l/',
      ),
      WrongWord(
        word: 'Conscientious',
        level: 'C1',
        definition: 'Tận tâm',
        mistakeExplanation: "Lỗi chính tả (double 's')",
      ),
    ];
  }

  @override
  Future<int> getPracticeStreak() async {
    return 15;
  }

  @override
  Future<int> getVocabularyCount() async {
    return 1248;
  }

  @override
  Future<int> getAccuracyPercentage() async {
    return 89;
  }
}
