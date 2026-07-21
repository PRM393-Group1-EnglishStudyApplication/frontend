class ExplanationModel {
  final String exerciseId;
  final String userAnswer;
  final String correctAnswer;
  final String whyWrong;
  final String whyCorrect;
  final String tip;
  final bool cached;

  const ExplanationModel({
    required this.exerciseId,
    required this.userAnswer,
    required this.correctAnswer,
    required this.whyWrong,
    required this.whyCorrect,
    required this.tip,
    required this.cached,
  });

  factory ExplanationModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> explanation =
        json['explanation'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    return ExplanationModel(
      exerciseId: json['exercise_id'] as String? ?? '',
      userAnswer: json['user_answer'] as String? ?? '',
      correctAnswer: json['correct_answer'] as String? ?? '',
      whyWrong: explanation['why_wrong'] as String? ?? '',
      whyCorrect: explanation['why_correct'] as String? ?? '',
      tip: explanation['tip'] as String? ?? '',
      cached: json['cached'] as bool? ?? false,
    );
  }
}
