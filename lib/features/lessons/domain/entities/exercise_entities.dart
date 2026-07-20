class Vocabulary {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String exampleSentence;
  final String? imageUrl;

  const Vocabulary({
    required this.id,
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.exampleSentence,
    this.imageUrl,
  });
}

class ExerciseOption {
  final String id;
  final String exerciseId;
  final String optionText;
  final bool isCorrect;

  const ExerciseOption({
    required this.id,
    required this.exerciseId,
    required this.optionText,
    required this.isCorrect,
  });
}

class Exercise {
  final String id;
  final String lessonId;
  final String question;
  final String exerciseType;
  final String correctAnswer;
  final String? lastUserAnswer;
  final String? audioUrl;
  final String? imageUrl;
  final List<ExerciseOption> options;

  const Exercise({
    required this.id,
    required this.lessonId,
    required this.question,
    required this.exerciseType,
    required this.correctAnswer,
    this.lastUserAnswer,
    this.audioUrl,
    this.imageUrl,
    required this.options,
  });
}

class LessonDetail {
  final String id;
  final String unitId;
  final String title;
  final int orderIndex;
  final int xpReward;
  final List<Vocabulary> vocabulary;
  final List<Exercise> exercises;

  const LessonDetail({
    required this.id,
    required this.unitId,
    required this.title,
    required this.orderIndex,
    required this.xpReward,
    required this.vocabulary,
    required this.exercises,
  });
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
}

class WrongAnswerPack {
  final List<Exercise> items;
  final int total;

  const WrongAnswerPack({required this.items, required this.total});
}

class WrongAnswerReviewResult {
  final int totalQuestions;
  final int correctAnswers;
  final int score;
  final int remainingWrongAnswers;

  const WrongAnswerReviewResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.remainingWrongAnswers,
  });
}
