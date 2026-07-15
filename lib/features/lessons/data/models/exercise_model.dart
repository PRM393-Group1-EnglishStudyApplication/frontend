class VocabularyModel {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String exampleSentence;

  const VocabularyModel({
    required this.id,
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.exampleSentence,
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

class ExerciseOptionModel {
  final String id;
  final String exerciseId;
  final String optionText;
  final bool isCorrect;

  const ExerciseOptionModel({
    required this.id,
    required this.exerciseId,
    required this.optionText,
    required this.isCorrect,
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

class ExerciseModel {
  final String id;
  final String lessonId;
  final String question;
  final String exerciseType;
  final String correctAnswer;
  final String? audioUrl;
  final String? imageUrl;
  final List<ExerciseOptionModel> options;

  const ExerciseModel({
    required this.id,
    required this.lessonId,
    required this.question,
    required this.exerciseType,
    required this.correctAnswer,
    this.audioUrl,
    this.imageUrl,
    required this.options,
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

class LessonDetailModel {
  final String id;
  final String unitId;
  final String title;
  final int orderIndex;
  final int xpReward;
  final List<VocabularyModel> vocabulary;
  final List<ExerciseModel> exercises;

  const LessonDetailModel({
    required this.id,
    required this.unitId,
    required this.title,
    required this.orderIndex,
    required this.xpReward,
    required this.vocabulary,
    required this.exercises,
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

class LessonSubmissionResult {
  final int totalQuestions;
  final int correctAnswers;
  final int score;
  final int earnedXp;
  final int currentHearts;
  final List<dynamic> unlockedAchievements;

  const LessonSubmissionResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.earnedXp,
    required this.currentHearts,
    required this.unlockedAchievements,
  });

  factory LessonSubmissionResult.fromJson(Map<String, dynamic> json) {
    return LessonSubmissionResult(
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      earnedXp: (json['earnedXp'] as num?)?.toInt() ?? 0,
      currentHearts: (json['currentHearts'] as num?)?.toInt() ?? 5,
      unlockedAchievements: json['unlockedAchievements'] as List<dynamic>? ?? [],
    );
  }
}
