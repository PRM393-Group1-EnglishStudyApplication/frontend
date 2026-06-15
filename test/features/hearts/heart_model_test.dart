import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/hearts/data/models/heart_model.dart';

void main() {
  test('HeartModel parses backend heart response', () {
    final HeartModel model = HeartModel.fromJson(<String, dynamic>{
      'user_id': 'user_123',
      'current_hearts': 3,
      'max_hearts': 5,
      'last_refill_at': '2026-06-15T10:00:00.000Z',
    });

    expect(model.userId, 'user_123');
    expect(model.currentHearts, 3);
    expect(model.maxHearts, 5);
    expect(model.lastRefillAt, DateTime.parse('2026-06-15T10:00:00.000Z'));
  });
}
