import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final StateProvider<String?> clerkTokenProvider = StateProvider<String?>((Ref ref) => null);

final Provider<Dio> authDioProvider = Provider<Dio>((Ref ref) {
  final String? token = ref.watch(clerkTokenProvider);
  final String rawUrl = dotenv.get('API_BASE_URL', fallback: 'https://backend-6i8r.onrender.com');
  final String baseUrl = rawUrl.replaceAll(RegExp(r'/+$'), '');

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: <String, dynamic>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ),
  );
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
