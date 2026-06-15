class CourseModel {
  final String id;
  final String title;
  final String description;
  final String targetLevel;

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetLevel,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetLevel: json['target_level'] as String? ?? 'beginner',
    );
  }
}
