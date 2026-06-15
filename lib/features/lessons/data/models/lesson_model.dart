class LessonModel {
  final String id;
  final String unitId;
  final String title;
  final int orderIndex;
  final int xpReward;

  const LessonModel({
    required this.id,
    required this.unitId,
    required this.title,
    required this.orderIndex,
    required this.xpReward,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      unitId: json['unit_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 1,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 10,
    );
  }
}
