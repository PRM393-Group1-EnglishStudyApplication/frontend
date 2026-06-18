class LessonModel {
  final String id;
  final String title;
  final int orderIndex;
  final int xpReward;
  final String unitId;

  const LessonModel({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.xpReward,
    required this.unitId,
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
