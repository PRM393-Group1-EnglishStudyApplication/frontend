class HeartStatus {
  final String userId;
  final int currentHearts;
  final int maxHearts;
  final DateTime? lastRefillAt;
  final DateTime? nextRefillAt;
  final int? secondsUntilNextRefill;

  const HeartStatus({
    required this.userId,
    required this.currentHearts,
    required this.maxHearts,
    this.lastRefillAt,
    this.nextRefillAt,
    this.secondsUntilNextRefill,
  });

  bool get isEmpty => currentHearts <= 0;
  bool get isFull => currentHearts >= maxHearts;

  HeartStatus copyWith({
    int? currentHearts,
    int? maxHearts,
    DateTime? lastRefillAt,
    DateTime? nextRefillAt,
    int? secondsUntilNextRefill,
  }) {
    return HeartStatus(
      userId: userId,
      currentHearts: currentHearts ?? this.currentHearts,
      maxHearts: maxHearts ?? this.maxHearts,
      lastRefillAt: lastRefillAt ?? this.lastRefillAt,
      nextRefillAt: nextRefillAt ?? this.nextRefillAt,
      secondsUntilNextRefill:
          secondsUntilNextRefill ?? this.secondsUntilNextRefill,
    );
  }
}
