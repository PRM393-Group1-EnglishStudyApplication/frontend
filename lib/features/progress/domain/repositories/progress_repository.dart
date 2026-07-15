import '../entities/progress_entry.dart';

abstract class ProgressRepository {
  Future<List<ProgressEntry>> getMyProgress();
}
