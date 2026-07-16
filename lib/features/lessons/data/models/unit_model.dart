import '../../domain/entities/unit.dart';

class UnitModel extends Unit {
  const UnitModel({
    required super.id,
    required super.courseId,
    required super.title,
    required super.orderIndex,
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
