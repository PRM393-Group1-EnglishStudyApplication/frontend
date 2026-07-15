import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.id,
    required super.userId,
    required super.weekStartDate,
    required super.xp,
    required super.rankPosition,
    super.user,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      weekStartDate: json['week_start_date'] as String? ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      rankPosition: (json['rank_position'] as num?)?.toInt() ?? 0,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      '_id': id,
      'user_id': userId,
      'week_start_date': weekStartDate,
      'xp': xp,
      'rank_position': rankPosition,
      if (user != null) 'user': (user as UserModel).toJson(),
    };
  }
}
