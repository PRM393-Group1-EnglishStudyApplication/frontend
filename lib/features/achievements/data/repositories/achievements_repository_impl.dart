import '../../domain/entities/achievement.dart';
import '../../domain/repositories/achievements_repository.dart';
import '../datasources/achievements_remote_data_source.dart';

class AchievementsRepositoryImpl implements AchievementsRepository {
  final AchievementsRemoteDataSource _remoteDataSource;

  AchievementsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Achievement>> getAchievements() {
    return _remoteDataSource.getAchievements();
  }

  @override
  Future<List<Achievement>> getMyAchievements() {
    return _remoteDataSource.getMyAchievements();
  }
}
