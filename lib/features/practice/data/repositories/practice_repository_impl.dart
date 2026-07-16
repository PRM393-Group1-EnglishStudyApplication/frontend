import '../../../lessons/domain/entities/exercise_entities.dart';
import '../../domain/repositories/practice_repository.dart';
import '../datasources/practice_remote_data_source.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  final PracticeRemoteDataSource _remoteDataSource;

  PracticeRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Exercise>> getPracticePack() {
    return _remoteDataSource.getPracticePack();
  }

  @override
  Future<LessonSubmissionResult> submitPracticePack(List<Map<String, dynamic>> answers) {
    return _remoteDataSource.submitPracticePack(answers);
  }
}
