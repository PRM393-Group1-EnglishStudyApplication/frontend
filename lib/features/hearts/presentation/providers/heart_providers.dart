import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/heart_remote_data_source.dart';
import '../../data/repositories/heart_repository_impl.dart';
import '../../domain/entities/heart_status.dart';
import '../../domain/repositories/heart_repository.dart';

const Duration heartRefillDuration = Duration(minutes: 10);

final Provider<HeartRemoteDataSource> heartRemoteDataSourceProvider =
    Provider<HeartRemoteDataSource>((Ref ref) {
      return HeartRemoteDataSourceImpl(ref.watch(authDioProvider));
    });

final Provider<HeartRepository> heartRepositoryProvider =
    Provider<HeartRepository>((Ref ref) {
      return HeartRepositoryImpl(ref.watch(heartRemoteDataSourceProvider));
    });

class HeartState {
  final HeartStatus? hearts;
  final Duration? refillRemaining;
  final bool isLoading;
  final bool isRefilling;
  final String? errorMessage;

  const HeartState({
    this.hearts,
    this.refillRemaining,
    this.isLoading = false,
    this.isRefilling = false,
    this.errorMessage,
  });

  bool get canStartLesson => hearts == null || !hearts!.isEmpty;
  bool get isOutOfHearts => hearts?.isEmpty ?? false;

  HeartState copyWith({
    HeartStatus? hearts,
    Duration? refillRemaining,
    bool clearRefillRemaining = false,
    bool? isLoading,
    bool? isRefilling,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HeartState(
      hearts: hearts ?? this.hearts,
      refillRemaining: clearRefillRemaining
          ? null
          : refillRemaining ?? this.refillRemaining,
      isLoading: isLoading ?? this.isLoading,
      isRefilling: isRefilling ?? this.isRefilling,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class HeartNotifier extends StateNotifier<HeartState> {
  final HeartRepository _repository;
  final String? _token;
  final DateTime Function() _now;
  Timer? _timer;

  HeartNotifier(
    this._repository,
    this._token, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(HeartState(isLoading: _token != null)) {
    if (_token != null) {
      loadHearts();
    }
  }

  Future<void> loadHearts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final HeartStatus hearts = await _repository.getMyHearts();
      final Duration? refillRemaining = _remainingFromServer(hearts);
      state = state.copyWith(
        hearts: hearts,
        refillRemaining: refillRemaining,
        clearRefillRemaining: refillRemaining == null,
        isLoading: false,
        clearError: true,
      );
      await _configureRefillTimer(hearts);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<bool> deductHeartOnError() async {
    final HeartStatus? hearts = state.hearts;
    if (hearts == null || hearts.isEmpty) {
      return false;
    }

      final HeartStatus updated = hearts.copyWith(
        currentHearts: (hearts.currentHearts - 1).clamp(0, hearts.maxHearts),
        nextRefillAt: hearts.nextRefillAt ?? _now().add(heartRefillDuration),
        secondsUntilNextRefill:
            hearts.secondsUntilNextRefill ?? heartRefillDuration.inSeconds,
      );
    state = state.copyWith(hearts: updated, clearError: true);
    await _configureRefillTimer(updated);
    return !updated.isEmpty;
  }

  Future<void> updateHeartCount(int currentHearts) async {
    final HeartStatus? hearts = state.hearts;
    if (hearts == null) {
      await loadHearts();
      return;
    }

      final HeartStatus updated = hearts.copyWith(
        currentHearts: currentHearts.clamp(0, hearts.maxHearts),
      );
    state = state.copyWith(hearts: updated, clearError: true);
    await _configureRefillTimer(updated);
  }

  Future<void> refillHearts() async {
    if (state.isRefilling) {
      return;
    }

    state = state.copyWith(isRefilling: true, clearError: true);
    try {
      final HeartStatus hearts = await _repository.refillHearts();
      state = state.copyWith(
        hearts: hearts,
        isRefilling: false,
        clearRefillRemaining: true,
        clearError: true,
      );
      _timer?.cancel();
    } catch (error) {
      state = state.copyWith(
        isRefilling: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> _configureRefillTimer(HeartStatus hearts) async {
    _timer?.cancel();

    if (hearts.isFull) {
      state = state.copyWith(clearRefillRemaining: true);
      return;
    }

    final DateTime deadline = hearts.nextRefillAt ??
        _now().add(
          Duration(
            seconds: hearts.secondsUntilNextRefill ?? heartRefillDuration.inSeconds,
          ),
        );

    await _updateCountdown(deadline);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown(deadline);
    });
  }

  Future<void> _updateCountdown(DateTime deadline) async {
    final Duration remaining = deadline.difference(_now());
    if (remaining <= Duration.zero) {
      _timer?.cancel();
      state = state.copyWith(refillRemaining: Duration.zero);
      await loadHearts();
      return;
    }
    state = state.copyWith(refillRemaining: remaining);
  }

  Duration? _remainingFromServer(HeartStatus hearts) {
    if (hearts.isFull) {
      return null;
    }
    if (hearts.secondsUntilNextRefill != null) {
      return Duration(seconds: hearts.secondsUntilNextRefill!.clamp(0, 1 << 31));
    }
    if (hearts.nextRefillAt != null) {
      final remaining = hearts.nextRefillAt!.difference(_now());
      return remaining.isNegative ? Duration.zero : remaining;
    }
    return heartRefillDuration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<HeartNotifier, HeartState> heartProvider =
    StateNotifierProvider<HeartNotifier, HeartState>((Ref ref) {
      return HeartNotifier(
        ref.watch(heartRepositoryProvider),
        ref.watch(clerkTokenProvider),
      );
    });
