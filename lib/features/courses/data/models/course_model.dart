class CourseModel {
  final String id;
  final String title;
  final String description;
  final String targetLevel;
  final String? imageUrl;
  final int? unitCount;

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetLevel,
    this.imageUrl,
    this.unitCount,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      targetLevel: (json['targetLevel'] ?? '') as String,
      imageUrl: json['imageUrl'] as String?,
      unitCount: json['unitCount'] as int?,
    );
  }
}
