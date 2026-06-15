import '../../domain/entities/heart_status.dart';

class HeartModel extends HeartStatus {
  const HeartModel({
    required super.userId,
    required super.currentHearts,
    required super.maxHearts,
    super.lastRefillAt,
  });

  factory HeartModel.fromJson(Map<String, dynamic> json) {
    final Object? rawUserId = json['user_id'];
    final String userId = rawUserId is Map<String, dynamic>
        ? rawUserId['_id']?.toString() ?? ''
        : rawUserId?.toString() ?? '';

    return HeartModel(
      userId: userId,
      currentHearts: (json['current_hearts'] as num?)?.toInt() ?? 0,
      maxHearts: (json['max_hearts'] as num?)?.toInt() ?? 5,
      lastRefillAt: DateTime.tryParse(json['last_refill_at']?.toString() ?? ''),
    );
  }
}
