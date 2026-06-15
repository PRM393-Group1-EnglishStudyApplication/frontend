import '../../../auth/domain/entities/app_user.dart';

class LeaderboardEntry {
  final String id;
  final String userId;
  final String weekStartDate;
  final int xp;
  final int rankPosition;
  final AppUser? user;

  const LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.xp,
    required this.rankPosition,
    this.user,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          weekStartDate == other.weekStartDate &&
          xp == other.xp &&
          rankPosition == other.rankPosition &&
          user == other.user;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      weekStartDate.hashCode ^
      xp.hashCode ^
      rankPosition.hashCode ^
      user.hashCode;
}
