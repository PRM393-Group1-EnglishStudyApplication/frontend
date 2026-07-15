import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/auth/data/models/user_model.dart';
import 'package:prm_frontend/features/auth/domain/entities/app_user.dart';

void main() {
  group('UserModel parsing tests', () {
    test('fromJson mapping parses all properties correctly', () {
      final json = {
        '_id': 'mongo_id_123',
        'clerk_user_id': 'clerk_id_456',
        'full_name': 'Jane Doe',
        'email': 'jane@example.com',
        'avatar_url': 'https://example.com/avatar.png',
        'total_xp': 350,
        'current_level': 'intermediate',
        'streak_count': 5,
      };

      final model = UserModel.fromJson(json);

      expect(model, isA<AppUser>());
      expect(model.id, 'mongo_id_123');
      expect(model.clerkUserId, 'clerk_id_456');
      expect(model.fullName, 'Jane Doe');
      expect(model.email, 'jane@example.com');
      expect(model.avatarUrl, 'https://example.com/avatar.png');
      expect(model.totalXp, 350);
      expect(model.currentLevel, 'intermediate');
      expect(model.streakCount, 5);
    });

    test('toJson produces correct Map structure', () {
      const model = UserModel(
        id: 'mongo_id_123',
        clerkUserId: 'clerk_id_456',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        avatarUrl: 'https://example.com/avatar.png',
        totalXp: 350,
        currentLevel: 'intermediate',
        streakCount: 5,
      );

      final json = model.toJson();

      expect(json['_id'], 'mongo_id_123');
      expect(json['clerk_user_id'], 'clerk_id_456');
      expect(json['full_name'], 'Jane Doe');
      expect(json['email'], 'jane@example.com');
      expect(json['avatar_url'], 'https://example.com/avatar.png');
      expect(json['total_xp'], 350);
      expect(json['current_level'], 'intermediate');
      expect(json['streak_count'], 5);
    });
  });
}
