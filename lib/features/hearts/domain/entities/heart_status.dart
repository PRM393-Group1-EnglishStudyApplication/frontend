class HeartStatus {
  final String userId;
  final int currentHearts;
  final int maxHearts;
  final DateTime? lastRefillAt;

  const HeartStatus({
    required this.userId,
    required this.currentHearts,
    required this.maxHearts,
    this.lastRefillAt,
  });

  bool get isEmpty => currentHearts <= 0;
  bool get isFull => currentHearts >= maxHearts;

  HeartStatus copyWith({
    int? currentHearts,
    int? maxHearts,
    DateTime? lastRefillAt,
  }) {
    return HeartStatus(
      userId: userId,
      currentHearts: currentHearts ?? this.currentHearts,
      maxHearts: maxHearts ?? this.maxHearts,
      lastRefillAt: lastRefillAt ?? this.lastRefillAt,
    );
  }
}
