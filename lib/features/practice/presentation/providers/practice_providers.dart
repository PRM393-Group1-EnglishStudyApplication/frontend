import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../lessons/domain/entities/exercise_entities.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../data/datasources/practice_remote_data_source.dart';
import '../../data/repositories/practice_repository_impl.dart';
import '../../domain/repositories/practice_repository.dart';

final Provider<PracticeRemoteDataSource> practiceRemoteDataSourceProvider =
    Provider<PracticeRemoteDataSource>((Ref ref) {
  final dio = ref.watch(authDioProvider);
  return PracticeRemoteDataSourceImpl(dio);
});

final Provider<PracticeRepository> practiceRepositoryProvider =
    Provider<PracticeRepository>((Ref ref) {
  final remoteDataSource = ref.watch(practiceRemoteDataSourceProvider);
  return PracticeRepositoryImpl(remoteDataSource);
});

final practicePackProvider =
    FutureProvider.autoDispose<List<Exercise>>((Ref ref) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticePack();
});

final wrongAnswerPackProvider =
    FutureProvider.autoDispose<WrongAnswerPack>((Ref ref) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getWrongAnswerPack();
});

final FutureProvider<int> completedLessonCountProvider =
    FutureProvider<int>((Ref ref) async {
  final summary = await ref.watch(progressSummaryProvider.future);
  return summary.completedLessons;
});

final FutureProvider<int> practiceStreakProvider =
    FutureProvider<int>((Ref ref) async {
  return ref.watch(currentUserProvider).maybeWhen(
        data: (user) => user.streakCount,
        orElse: () => 0,
      );
});

final FutureProvider<int> earnedXpProvider =
    FutureProvider<int>((Ref ref) async {
  final summary = await ref.watch(progressSummaryProvider.future);
  return summary.totalXp;
});

final FutureProvider<int> accuracyPercentageProvider =
    FutureProvider<int>((Ref ref) async {
  final summary = await ref.watch(progressSummaryProvider.future);
  return summary.averageScore;
});
