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
    final units = json['units'] as List<dynamic>?;
    return CourseModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      targetLevel: (json['target_level'] ?? json['targetLevel'] ?? '') as String,
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      unitCount: units?.length ?? json['unitCount'] as int?,
    );
  }
}
