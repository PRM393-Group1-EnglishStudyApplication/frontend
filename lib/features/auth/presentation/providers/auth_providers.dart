import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final StateProvider<String?> clerkTokenProvider = StateProvider<String?>((Ref ref) => null);

final Provider<Dio> authDioProvider = Provider<Dio>((Ref ref) {
  final String rawUrl = dotenv.get('API_BASE_URL', fallback: 'https://backend-6i8r.onrender.com');
  final String baseUrl = rawUrl.replaceAll(RegExp(r'/+$'), '');

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: <String, dynamic>{
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
      final String? token = ref.read(clerkTokenProvider);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ));

  dio.interceptors.add(LogInterceptor(
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    logPrint: (Object object) => print('DIO_LOG: $object'),
  ));

  return dio;
});

final Provider<AuthRemoteDataSource> authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((Ref ref) {
  final Dio dio = ref.watch(authDioProvider);
  return AuthRemoteDataSourceImpl(dio);
});

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  final AuthRemoteDataSource remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
});

class CurrentUserNotifier extends StateNotifier<AsyncValue<AppUser>> {
  final AuthRepository _repository;
  final String? _token;

  CurrentUserNotifier(this._repository, this._token) : super(const AsyncValue<AppUser>.loading()) {
    if (_token != null) {
      loadUser();
    }
  }

  Future<void> loadUser() async {
    state = const AsyncValue<AppUser>.loading();
    try {
      final AppUser user = await _repository.getCurrentUser();

      // Try to apply onboarding overlay from SharedPreferences.
      // If the plugin is unavailable (e.g. missing native rebuild), skip
      // the overlay gracefully and still show the base user profile.
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // Check for temporary onboarding choices (not yet mapped to logged-in user)
        final String? tempPurpose = prefs.getString('onboarding_purpose');
        final String? tempLevel = prefs.getString('onboarding_level');
        final int? tempScore = prefs.getInt('onboarding_score');

        if (tempPurpose != null && tempLevel != null && tempScore != null) {
          // Map to user-specific keys
          await prefs.setString('onboarding_purpose_${user.id}', tempPurpose);
          await prefs.setString('onboarding_level_${user.id}', tempLevel);
          await prefs.setInt('onboarding_score_${user.id}', tempScore);

          // Clear temporary keys
          await prefs.remove('onboarding_purpose');
          await prefs.remove('onboarding_level');
          await prefs.remove('onboarding_score');
        }

        // Read user-specific onboarding choices
        final String? purpose = prefs.getString('onboarding_purpose_${user.id}');
        final String? level = prefs.getString('onboarding_level_${user.id}');
        final int? score = prefs.getInt('onboarding_score_${user.id}');

        if (purpose != null && level != null && score != null) {
          final String mappedLevel = level.toUpperCase() == 'BEGINNER' ? 'beginner' : 'elementary';
          final int extraXp = score * 50;

          final AppUser updatedUser = AppUser(
            id: user.id,
            clerkUserId: user.clerkUserId,
            fullName: user.fullName,
            email: user.email,
            avatarUrl: user.avatarUrl,
            totalXp: user.totalXp + extraXp,
            currentLevel: mappedLevel,
            streakCount: user.streakCount,
          );
          state = AsyncValue<AppUser>.data(updatedUser);
          return;
        }
      } catch (prefsError) {
        // SharedPreferences plugin not available (MissingPluginException).
        // This happens when the app hasn't been fully rebuilt after adding
        // the shared_preferences dependency. Fall through to show base user.
        print('SharedPreferences unavailable, skipping onboarding overlay: $prefsError');
      }

      state = AsyncValue<AppUser>.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue<AppUser>.error(error, stackTrace);
    }
  }
}

final StateNotifierProvider<CurrentUserNotifier, AsyncValue<AppUser>> currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<AppUser>>((Ref ref) {
  final AuthRepository repository = ref.watch(authRepositoryProvider);
  final String? token = ref.watch(clerkTokenProvider);
  return CurrentUserNotifier(repository, token);
});
