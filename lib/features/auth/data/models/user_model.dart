import '../../domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    super.clerkUserId,
    super.fullName,
    required super.email,
    super.avatarUrl,
    required super.totalXp,
    required super.currentLevel,
    required super.streakCount,
    super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      clerkUserId: json['clerk_user_id'] as String?,
      fullName: json['full_name'] as String?,
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      currentLevel: json['current_level'] as String? ?? 'beginner',
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? 'student',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      '_id': id,
      'clerk_user_id': clerkUserId,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'total_xp': totalXp,
      'current_level': currentLevel,
      'streak_count': streakCount,
      'role': role,
    };
  }
}
