import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/leaderboard_remote_data_source.dart';
import '../../data/repositories/leaderboard_repository_impl.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';

final Provider<LeaderboardRemoteDataSource> leaderboardRemoteDataSourceProvider =
    Provider<LeaderboardRemoteDataSource>((Ref ref) {
  final dio = ref.watch(authDioProvider);
  return LeaderboardRemoteDataSourceImpl(dio);
});

final Provider<LeaderboardRepository> leaderboardRepositoryProvider =
    Provider<LeaderboardRepository>((Ref ref) {
  final remoteDataSource = ref.watch(leaderboardRemoteDataSourceProvider);
  return LeaderboardRepositoryImpl(remoteDataSource);
});

final FutureProvider<List<LeaderboardEntry>> leaderboardDataProvider =
    FutureProvider<List<LeaderboardEntry>>((Ref ref) async {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getCurrentLeaderboard();
});

final FutureProvider<LeaderboardEntry> myLeaderboardProvider =
    FutureProvider<LeaderboardEntry>((Ref ref) async {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getMyLeaderboard();
});

class LeaderboardViewData {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry myEntry;

  const LeaderboardViewData({
    required this.entries,
    required this.myEntry,
  });
}

final FutureProvider<LeaderboardViewData> leaderboardViewProvider =
    FutureProvider<LeaderboardViewData>((Ref ref) async {
  final entries = await ref.watch(leaderboardDataProvider.future);
  final myEntry = await ref.watch(myLeaderboardProvider.future);
  return LeaderboardViewData(entries: entries, myEntry: myEntry);
});
