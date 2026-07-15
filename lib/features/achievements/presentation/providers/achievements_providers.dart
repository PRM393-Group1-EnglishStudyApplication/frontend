import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/achievements_remote_data_source.dart';
import '../../data/repositories/achievements_repository_impl.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/repositories/achievements_repository.dart';

final Provider<AchievementsRemoteDataSource> achievementsRemoteDataSourceProvider =
    Provider<AchievementsRemoteDataSource>((Ref ref) {
  final dio = ref.watch(authDioProvider);
  return AchievementsRemoteDataSourceImpl(dio);
});

final Provider<AchievementsRepository> achievementsRepositoryProvider =
    Provider<AchievementsRepository>((Ref ref) {
  final remoteDataSource = ref.watch(achievementsRemoteDataSourceProvider);
  return AchievementsRepositoryImpl(remoteDataSource);
});

final FutureProvider<List<Achievement>> allAchievementsDataProvider =
    FutureProvider<List<Achievement>>((Ref ref) async {
  final repository = ref.watch(achievementsRepositoryProvider);
  return repository.getAchievements();
});

final FutureProvider<List<Achievement>> myAchievementsDataProvider =
    FutureProvider<List<Achievement>>((Ref ref) async {
  final repository = ref.watch(achievementsRepositoryProvider);
  return repository.getMyAchievements();
});

final FutureProvider<List<Achievement>> combinedAchievementsProvider =
    FutureProvider<List<Achievement>>((Ref ref) async {
  final all = await ref.watch(allAchievementsDataProvider.future);
  final my = await ref.watch(myAchievementsDataProvider.future);

  final myMap = {for (var achievement in my) achievement.id: achievement};

  return all.map((achievement) {
    final unlocked = myMap[achievement.id];
    if (unlocked != null) {
      return achievement.copyWith(
        isUnlocked: true,
        unlockedAt: unlocked.unlockedAt,
      );
    }
    return achievement;
  }).toList();
});
