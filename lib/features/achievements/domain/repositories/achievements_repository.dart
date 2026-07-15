import '../entities/achievement.dart';

abstract class AchievementsRepository {
  Future<List<Achievement>> getAchievements();
  Future<List<Achievement>> getMyAchievements();
}
