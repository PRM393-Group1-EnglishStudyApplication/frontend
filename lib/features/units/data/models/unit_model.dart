class UnitModel {
  final String id;
  final String title;
  final int orderIndex;
  final String courseId;

  const UnitModel({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.courseId,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      orderIndex: (json['orderIndex'] ?? json['order'] ?? 0) as int,
      courseId: (json['courseId'] ?? '') as String,
    );
  }
}
