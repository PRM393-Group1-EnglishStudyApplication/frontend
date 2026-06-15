import '../../domain/entities/achievement.dart';

class AchievementModel extends Achievement {
  const AchievementModel({
    required super.id,
    required super.name,
    super.description,
    super.iconUrl,
    required super.requiredXp,
    required super.isUnlocked,
    super.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      requiredXp: (json['required_xp'] as num?)?.toInt() ?? 0,
      isUnlocked: false,
      unlockedAt: null,
    );
  }

  factory AchievementModel.fromUserAchievementJson(Map<String, dynamic> json) {
    final achievementJson = json['achievement'] as Map<String, dynamic>? ?? {};
    final unlockedAtStr = json['unlocked_at'] as String?;
    return AchievementModel(
      id: achievementJson['_id'] as String? ?? achievementJson['id'] as String? ?? json['achievement_id'] as String? ?? '',
      name: achievementJson['name'] as String? ?? '',
      description: achievementJson['description'] as String?,
      iconUrl: achievementJson['icon_url'] as String?,
      requiredXp: (achievementJson['required_xp'] as num?)?.toInt() ?? 0,
      isUnlocked: true,
      unlockedAt: unlockedAtStr != null ? DateTime.parse(unlockedAtStr) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      '_id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'required_xp': requiredXp,
    };
  }
}
