class AppUser {
  final String id;
  final String? clerkUserId;
  final String? fullName;
  final String email;
  final String? avatarUrl;
  final int totalXp;
  final String currentLevel;
  final int streakCount;

  const AppUser({
    required this.id,
    this.clerkUserId,
    this.fullName,
    required this.email,
    this.avatarUrl,
    required this.totalXp,
    required this.currentLevel,
    required this.streakCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clerkUserId == other.clerkUserId &&
          fullName == other.fullName &&
          email == other.email &&
          avatarUrl == other.avatarUrl &&
          totalXp == other.totalXp &&
          currentLevel == other.currentLevel &&
          streakCount == other.streakCount;

  @override
  int get hashCode =>
      id.hashCode ^
      clerkUserId.hashCode ^
      fullName.hashCode ^
      email.hashCode ^
      avatarUrl.hashCode ^
      totalXp.hashCode ^
      currentLevel.hashCode ^
      streakCount.hashCode;
}
