import '../../../lessons/data/models/exercise_model.dart';

class MatchPlayer {
  final String userId;
  final String fullName;
  final String avatarUrl;
  final bool isReady;
  final bool isConnected;
  final int score;
  final int correctCount;

  const MatchPlayer({
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    this.isReady = false,
    this.isConnected = true,
    this.score = 0,
    this.correctCount = 0,
  });

  factory MatchPlayer.fromJson(Map<String, dynamic> json) {
    return MatchPlayer(
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String? ?? '',
      isReady: json['isReady'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? true,
      score: json['score'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
    );
  }

  MatchPlayer copyWith({
    String? userId,
    String? fullName,
    String? avatarUrl,
    bool? isReady,
    bool? isConnected,
    int? score,
    int? correctCount,
  }) {
    return MatchPlayer(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isReady: isReady ?? this.isReady,
      isConnected: isConnected ?? this.isConnected,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
    );
  }
}

class MatchQuestion {
  final int index;
  final DateTime endsAt;
  final ExerciseModel exercise;

  const MatchQuestion({
    required this.index,
    required this.endsAt,
    required this.exercise,
  });

  factory MatchQuestion.fromJson(Map<String, dynamic> json) {
    return MatchQuestion(
      index: json['index'] as int? ?? 0,
      endsAt: DateTime.parse(json['endsAt'] as String).toLocal(),
      exercise: ExerciseModel.fromJson(json['exercise'] as Map<String, dynamic>),
    );
  }
}

class MatchResult {
  final Map<String, int> scores;
  final String? winnerUserId;
  final Map<String, int> xpAwarded;

  const MatchResult({
    required this.scores,
    this.winnerUserId,
    required this.xpAwarded,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final scoresMap = (json['scores'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    ) ?? {};
    final xpMap = (json['xpAwarded'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    ) ?? {};

    return MatchResult(
      scores: scoresMap,
      winnerUserId: json['winnerUserId'] as String?,
      xpAwarded: xpMap,
    );
  }
}
