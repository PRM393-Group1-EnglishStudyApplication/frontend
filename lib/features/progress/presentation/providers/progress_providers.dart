import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/progress_remote_data_source.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../domain/entities/progress_entry.dart';
import '../../domain/repositories/progress_repository.dart';

final Provider<ProgressRemoteDataSource> progressRemoteDataSourceProvider =
    Provider<ProgressRemoteDataSource>((Ref ref) {
  return ProgressRemoteDataSourceImpl(ref.watch(authDioProvider));
});

final Provider<ProgressRepository> progressRepositoryProvider =
    Provider<ProgressRepository>((Ref ref) {
  return ProgressRepositoryImpl(ref.watch(progressRemoteDataSourceProvider));
});

final FutureProvider<List<ProgressEntry>> progressEntriesProvider =
    FutureProvider<List<ProgressEntry>>((Ref ref) async {
  final repository = ref.watch(progressRepositoryProvider);
  return repository.getMyProgress();
});

final FutureProvider<ProgressSummary> progressSummaryProvider =
    FutureProvider<ProgressSummary>((Ref ref) async {
  final entries = await ref.watch(progressEntriesProvider.future);
  return ProgressSummary.fromEntries(entries);
});
