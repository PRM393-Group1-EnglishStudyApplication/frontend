import '../../domain/entities/progress_entry.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_remote_data_source.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressRemoteDataSource _remoteDataSource;

  ProgressRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ProgressEntry>> getMyProgress() async {
    final models = await _remoteDataSource.getMyProgress();
    return List<ProgressEntry>.from(models);
  }
}
