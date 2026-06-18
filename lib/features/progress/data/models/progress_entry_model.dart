import '../../domain/entities/progress_entry.dart';

class ProgressEntryModel extends ProgressEntry {
  const ProgressEntryModel({
    required super.id,
    required super.lessonId,
    required super.lessonTitle,
    required super.isCompleted,
    required super.score,
    required super.earnedXp,
    super.completedAt,
  });

  factory ProgressEntryModel.fromJson(Map<String, dynamic> json) {
    final Object? rawLessonId = json['lesson_id'];
    final Map<String, dynamic>? lessonJson =
        json['lesson'] as Map<String, dynamic>?;
    final String lessonId = rawLessonId is Map<String, dynamic>
        ? rawLessonId['_id']?.toString() ?? ''
        : rawLessonId?.toString() ?? lessonJson?['_id']?.toString() ?? '';

    return ProgressEntryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      lessonId: lessonId,
      lessonTitle: lessonJson?['title']?.toString() ?? 'Lesson',
      isCompleted: json['is_completed'] as bool? ?? false,
      score: (json['score'] as num?)?.toInt() ?? 0,
      earnedXp: (json['earned_xp'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
    );
  }
}
