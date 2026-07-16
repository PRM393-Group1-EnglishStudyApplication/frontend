import '../../domain/entities/lesson.dart';

class LessonModel extends Lesson {
  const LessonModel({
    required super.id,
    required super.title,
    required super.orderIndex,
    required super.xpReward,
    required super.unitId,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      orderIndex:
          (json['order_index'] ?? json['orderIndex'] ?? json['order'] ?? 0)
              as int,
      xpReward:
          (json['xp_reward'] ?? json['xpReward'] ?? json['xp'] ?? 10) as int,
      unitId: (json['unit_id'] ?? json['unitId'] ?? '').toString(),
    );
  }
}
