class UnitModel {
  final String id;
  final String courseId;
  final String title;
  final int orderIndex;

  const UnitModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.orderIndex,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 1,
    );
  }
}
