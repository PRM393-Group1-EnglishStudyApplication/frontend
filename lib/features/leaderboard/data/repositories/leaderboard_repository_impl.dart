import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_data_source.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDataSource _remoteDataSource;

  LeaderboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<LeaderboardEntry>> getCurrentLeaderboard() {
    return _remoteDataSource.getCurrentLeaderboard();
  }

  @override
  Future<LeaderboardEntry> getMyLeaderboard() {
    return _remoteDataSource.getMyLeaderboard();
  }
}
