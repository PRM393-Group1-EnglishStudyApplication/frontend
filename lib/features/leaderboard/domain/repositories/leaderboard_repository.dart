import '../entities/leaderboard_entry.dart';

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getCurrentLeaderboard();
  Future<LeaderboardEntry> getMyLeaderboard();
}
