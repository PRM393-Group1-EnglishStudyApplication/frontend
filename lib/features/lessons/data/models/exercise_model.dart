import '../../domain/entities/exercise_entities.dart';

class VocabularyModel extends Vocabulary {
  const VocabularyModel({
    required super.id,
    required super.word,
    required super.meaning,
    required super.pronunciation,
    required super.exampleSentence,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    return VocabularyModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      word: json['word'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      pronunciation: json['pronunciation'] as String? ?? '',
      exampleSentence: json['example_sentence'] as String? ?? '',
    );
  }
}

class ExerciseOptionModel extends ExerciseOption {
  const ExerciseOptionModel({
    required super.id,
    required super.exerciseId,
    required super.optionText,
    required super.isCorrect,
  });

  factory ExerciseOptionModel.fromJson(Map<String, dynamic> json) {
    return ExerciseOptionModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      exerciseId: json['exercise_id'] as String? ?? '',
      optionText: json['option_text'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

class ExerciseModel extends Exercise {
  const ExerciseModel({
    required super.id,
    required super.lessonId,
    required super.question,
    required super.exerciseType,
    required super.correctAnswer,
    super.audioUrl,
    super.imageUrl,
    required List<ExerciseOptionModel> super.options,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    final opts = json['options'] as List<dynamic>? ?? [];
    return ExerciseModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      lessonId: json['lesson_id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      exerciseType: json['exercise_type'] as String? ?? 'multiple_choice',
      correctAnswer: json['correct_answer'] as String? ?? '',
      audioUrl: json['audio_url'] as String?,
      imageUrl: json['image_url'] as String?,
      options: opts.map((opt) => ExerciseOptionModel.fromJson(opt as Map<String, dynamic>)).toList(),
    );
  }
}

class LessonDetailModel extends LessonDetail {
  const LessonDetailModel({
    required super.id,
    required super.unitId,
    required super.title,
    required super.orderIndex,
    required super.xpReward,
    required List<VocabularyModel> super.vocabulary,
    required List<ExerciseModel> super.exercises,
  });

  factory LessonDetailModel.fromJson(Map<String, dynamic> json) {
    final vocabs = json['vocabulary'] as List<dynamic>? ?? [];
    final exers = json['exercises'] as List<dynamic>? ?? [];

    return LessonDetailModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      unitId: json['unit_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 1,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 10,
      vocabulary: vocabs.map((v) => VocabularyModel.fromJson(v as Map<String, dynamic>)).toList(),
      exercises: exers.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class LessonSubmissionResultModel extends LessonSubmissionResult {
  const LessonSubmissionResultModel({
    required super.totalQuestions,
    required super.correctAnswers,
    required super.score,
    required super.earnedXp,
    required super.currentHearts,
    required super.unlockedAchievements,
  });

  factory LessonSubmissionResultModel.fromJson(Map<String, dynamic> json) {
    return LessonSubmissionResultModel(
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      earnedXp: (json['earnedXp'] as num?)?.toInt() ?? 0,
      currentHearts: (json['currentHearts'] as num?)?.toInt() ?? 5,
      unlockedAchievements: json['unlockedAchievements'] as List<dynamic>? ?? [],
    );
  }
}
