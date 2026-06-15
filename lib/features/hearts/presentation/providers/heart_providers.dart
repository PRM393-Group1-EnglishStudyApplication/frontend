import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/heart_remote_data_source.dart';
import '../../data/repositories/heart_repository_impl.dart';
import '../../domain/entities/heart_status.dart';
import '../../domain/repositories/heart_repository.dart';

const Duration heartRefillDuration = Duration(hours: 5);

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
  final Future<SharedPreferences> Function() _preferencesFactory;
  final DateTime Function() _now;
  Timer? _timer;

  HeartNotifier(
    this._repository,
    this._token, {
    Future<SharedPreferences> Function()? preferencesFactory,
    DateTime Function()? now,
  }) : _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now,
       super(HeartState(isLoading: _token != null)) {
    if (_token != null) {
      loadHearts();
    }
  }

  Future<void> loadHearts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final HeartStatus hearts = await _repository.getMyHearts();
      state = state.copyWith(
        hearts: hearts,
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
      await _clearRefillDeadline(hearts.userId);
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
      await _clearRefillDeadline(hearts.userId);
      state = state.copyWith(clearRefillRemaining: true);
      return;
    }

    final SharedPreferences preferences = await _preferencesFactory();
    final String key = _deadlineKey(hearts.userId);
    final String? storedDeadline = preferences.getString(key);
    DateTime? deadline = DateTime.tryParse(storedDeadline ?? '');

    if (deadline == null) {
      deadline = _now().add(heartRefillDuration);
      await preferences.setString(key, deadline.toIso8601String());
    }

    await _updateCountdown(deadline);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown(deadline!);
    });
  }

  Future<void> _updateCountdown(DateTime deadline) async {
    final Duration remaining = deadline.difference(_now());
    if (remaining <= Duration.zero) {
      _timer?.cancel();
      state = state.copyWith(refillRemaining: Duration.zero);
      await refillHearts();
      return;
    }
    state = state.copyWith(refillRemaining: remaining);
  }

  Future<void> _clearRefillDeadline(String userId) async {
    if (userId.isEmpty) {
      return;
    }
    final SharedPreferences preferences = await _preferencesFactory();
    await preferences.remove(_deadlineKey(userId));
  }

  String _deadlineKey(String userId) => 'heart_refill_deadline_$userId';

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
