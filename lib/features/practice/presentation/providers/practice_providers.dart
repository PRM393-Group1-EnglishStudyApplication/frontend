import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/practice_repository_impl.dart';
import '../../domain/entities/wrong_word.dart';
import '../../domain/repositories/practice_repository.dart';

final Provider<PracticeRepository> practiceRepositoryProvider =
    Provider<PracticeRepository>((Ref ref) {
  return PracticeRepositoryImpl();
});

final FutureProvider<List<WrongWord>> wrongWordsDataProvider =
    FutureProvider<List<WrongWord>>((Ref ref) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getWrongWords();
});

final FutureProvider<int> practiceStreakProvider =
    FutureProvider<int>((Ref ref) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeStreak();
});

final FutureProvider<int> vocabularyCountProvider =
    FutureProvider<int>((Ref ref) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getVocabularyCount();
});

final FutureProvider<int> accuracyPercentageProvider =
    FutureProvider<int>((Ref ref) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getAccuracyPercentage();
});
