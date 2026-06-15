import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/core/errors/failures.dart';
import 'package:prm_frontend/features/auth/domain/entities/app_user.dart';
import 'package:prm_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:prm_frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepository implements AuthRepository {
  AppUser? user;
  Object? exception;
  int callCount = 0;

  @override
  Future<AppUser> getCurrentUser() async {
    callCount++;
    if (exception != null) {
      throw exception!;
    }
    if (user != null) {
      return user!;
    }
    throw Exception('No fake user provided');
  }
}

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    fakeRepository = FakeAuthRepository();
  });

  ProviderContainer createContainer({
    String? token,
  }) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
        if (token != null) clerkTokenProvider.overrideWith((ref) => token),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('currentUserProvider tests', () {
    const testUser = AppUser(
      id: '123',
      email: 'jane@example.com',
      totalXp: 10,
      currentLevel: 'beginner',
      streakCount: 1,
    );

    test('is in Loading state initially when token is present and fetches user', () async {
      fakeRepository.user = testUser;

      final container = createContainer(token: 'valid_jwt');

      // The notifier constructor fires loadUser asynchronously.
      // We can await the loadUser call or wait for the provider to update.
      await container.read(currentUserProvider.notifier).loadUser();

      final state = container.read(currentUserProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, testUser);
      expect(fakeRepository.callCount, 2); // 1 from constructor, 1 from manual loadUser
    });

    test('is in Loading state and does not fetch if token is null', () async {
      final container = createContainer(token: null);

      final state = container.read(currentUserProvider);
      expect(state, const AsyncValue<AppUser>.loading());
      expect(fakeRepository.callCount, 0);
    });

    test('sets state to AsyncError when repository throws', () async {
      const errorFailure = ServerFailure('Internal Server Error');
      fakeRepository.exception = errorFailure;

      final container = createContainer(token: 'valid_jwt');

      await container.read(currentUserProvider.notifier).loadUser();

      final state = container.read(currentUserProvider);
      expect(state.hasError, isTrue);
      expect(state.error, errorFailure);
    });
    test('applies onboarding progress overlay when cached values exist in SharedPreferences', () async {
      fakeRepository.user = testUser;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('onboarding_purpose', 'travel');
      await prefs.setString('onboarding_level', 'EXPERIENCED');
      await prefs.setInt('onboarding_score', 3);

      final container = createContainer(token: 'valid_jwt');

      await container.read(currentUserProvider.notifier).loadUser();

      final state = container.read(currentUserProvider);
      expect(state.hasValue, isTrue);
      
      final AppUser user = state.value!;
      expect(user.totalXp, 160);
      expect(user.currentLevel, 'elementary');

      expect(prefs.containsKey('onboarding_purpose'), isFalse);
      expect(prefs.containsKey('onboarding_level'), isFalse);
      expect(prefs.containsKey('onboarding_score'), isFalse);

      expect(prefs.getString('onboarding_purpose_123'), 'travel');
      expect(prefs.getString('onboarding_level_123'), 'EXPERIENCED');
      expect(prefs.getInt('onboarding_score_123'), 3);
    });
  });
}
