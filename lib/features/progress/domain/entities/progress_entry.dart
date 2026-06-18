class ProgressEntry {
  final String id;
  final String lessonId;
  final String lessonTitle;
  final bool isCompleted;
  final int score;
  final int earnedXp;
  final DateTime? completedAt;

  const ProgressEntry({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.isCompleted,
    required this.score,
    required this.earnedXp,
    this.completedAt,
  });
}

class ProgressSummary {
  final int completedLessons;
  final int totalXp;
  final int averageScore;
  final List<ProgressEntry> latestCompletedLessons;

  const ProgressSummary({
    required this.completedLessons,
    required this.totalXp,
    required this.averageScore,
    required this.latestCompletedLessons,
  });

  factory ProgressSummary.fromEntries(List<ProgressEntry> entries) {
    final completed = entries.where((entry) => entry.isCompleted).toList()
      ..sort((a, b) {
        final aDate = a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    final scored = entries.where((entry) => entry.score > 0).toList();
    final totalScore = scored.fold<int>(0, (sum, entry) => sum + entry.score);

    return ProgressSummary(
      completedLessons: completed.length,
      totalXp: entries.fold<int>(0, (sum, entry) => sum + entry.earnedXp),
      averageScore: scored.isEmpty ? 0 : (totalScore / scored.length).round(),
      latestCompletedLessons: completed.take(5).toList(),
    );
  }
}
