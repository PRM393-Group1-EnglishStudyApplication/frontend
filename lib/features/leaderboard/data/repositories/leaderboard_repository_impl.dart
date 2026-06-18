import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_data_source.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDataSource _remoteDataSource;

  LeaderboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<LeaderboardEntry>> getCurrentLeaderboard() async {
    final models = await _remoteDataSource.getCurrentLeaderboard();
    return List<LeaderboardEntry>.from(models);
  }

  @override
  Future<LeaderboardEntry> getMyLeaderboard() {
    return _remoteDataSource.getMyLeaderboard();
  }
}
