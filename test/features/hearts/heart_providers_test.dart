import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/hearts/domain/entities/heart_status.dart';
import 'package:prm_frontend/features/hearts/domain/repositories/heart_repository.dart';
import 'package:prm_frontend/features/hearts/presentation/providers/heart_providers.dart';

class FakeHeartRepository implements HeartRepository {
  HeartStatus hearts;
  int getCallCount = 0;
  int refillCallCount = 0;

  FakeHeartRepository(this.hearts);

  @override
  Future<HeartStatus> getMyHearts() async {
    getCallCount++;
    if (getCallCount > 1 && hearts.nextRefillAt != null) {
      hearts = hearts.copyWith(
        currentHearts: (hearts.currentHearts + 1).clamp(0, hearts.maxHearts),
        nextRefillAt: DateTime(2026, 6, 15, 8, 10),
        secondsUntilNextRefill: 600,
      );
    }
    return hearts;
  }

  @override
  Future<HeartStatus> refillHearts() async {
    refillCallCount++;
    hearts = hearts.copyWith(
      currentHearts: hearts.maxHearts,
      lastRefillAt: DateTime(2026, 6, 15, 12),
    );
    return hearts;
  }
}

void main() {
  late DateTime now;
  late FakeHeartRepository repository;
  late HeartNotifier notifier;

  setUp(() {
    now = DateTime(2026, 6, 15, 8);
    repository = FakeHeartRepository(
      const HeartStatus(
        userId: 'user_123',
        currentHearts: 2,
        maxHearts: 5,
        secondsUntilNextRefill: 600,
      ),
    );
    notifier = HeartNotifier(repository, null, now: () => now);
  });

  tearDown(() {
    notifier.dispose();
  });

  test('loads hearts and uses server-provided refill countdown', () async {
    await notifier.loadHearts();

    expect(notifier.state.hearts?.currentHearts, 2);
    expect(notifier.state.refillRemaining, const Duration(minutes: 10));
    expect(notifier.state.canStartLesson, isTrue);
  });

  test('deducts one heart on error and blocks lessons at zero', () async {
    await notifier.loadHearts();

    expect(await notifier.deductHeartOnError(), isTrue);
    expect(notifier.state.hearts?.currentHearts, 1);

    expect(await notifier.deductHeartOnError(), isFalse);
    expect(notifier.state.hearts?.currentHearts, 0);
    expect(notifier.state.canStartLesson, isFalse);
    expect(notifier.state.isOutOfHearts, isTrue);
  });

  test('updates count from lesson submit response', () async {
    await notifier.loadHearts();

    await notifier.updateHeartCount(1);

    expect(notifier.state.hearts?.currentHearts, 1);
  });

  test('manual refill uses backend and restores maximum hearts', () async {
    await notifier.loadHearts();

    await notifier.refillHearts();

    expect(repository.refillCallCount, 1);
    expect(notifier.state.hearts?.currentHearts, 5);
    expect(notifier.state.refillRemaining, isNull);
  });

  test('expired timer reloads hearts from backend', () async {
    repository.hearts = HeartStatus(
      userId: 'user_123',
      currentHearts: 2,
      maxHearts: 5,
      nextRefillAt: now.subtract(const Duration(seconds: 1)),
    );

    await notifier.loadHearts();
    await Future<void>.delayed(Duration.zero);

    expect(repository.getCallCount, greaterThanOrEqualTo(2));
    expect(repository.refillCallCount, 0);
  });
}
