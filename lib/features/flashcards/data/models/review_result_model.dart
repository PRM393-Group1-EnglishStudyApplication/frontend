class ReviewUpdateModel {
  final String vocabularyId;
  final int box;
  final DateTime? nextReviewAt;

  const ReviewUpdateModel({
    required this.vocabularyId,
    required this.box,
    this.nextReviewAt,
  });

  factory ReviewUpdateModel.fromJson(Map<String, dynamic> json) {
    return ReviewUpdateModel(
      vocabularyId: json['vocabulary_id'] as String? ?? '',
      box: json['box'] as int? ?? 1,
      nextReviewAt: DateTime.tryParse(json['next_review_at'] as String? ?? ''),
    );
  }
}

class ReviewSubmitResultModel {
  final List<ReviewUpdateModel> updated;
  final int earnedXp;
  final int dailyXpRemaining;

  const ReviewSubmitResultModel({
    required this.updated,
    required this.earnedXp,
    required this.dailyXpRemaining,
  });

  factory ReviewSubmitResultModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> updatedJson = json['updated'] as List<dynamic>? ?? const <dynamic>[];
    return ReviewSubmitResultModel(
      updated: updatedJson.map((item) => ReviewUpdateModel.fromJson(item as Map<String, dynamic>)).toList(),
      earnedXp: json['earned_xp'] as int? ?? 0,
      dailyXpRemaining: json['daily_xp_remaining'] as int? ?? 0,
    );
  }
}
