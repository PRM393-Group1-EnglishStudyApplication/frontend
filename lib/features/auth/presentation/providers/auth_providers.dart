import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';

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

final Provider<GetCurrentUser> getCurrentUserProvider = Provider<GetCurrentUser>((Ref ref) {
  final AuthRepository repository = ref.watch(authRepositoryProvider);
  return GetCurrentUser(repository);
});

class CurrentUserNotifier extends StateNotifier<AsyncValue<AppUser>> {
  final GetCurrentUser _getCurrentUser;
  final String? _token;

  CurrentUserNotifier(this._getCurrentUser, this._token) : super(const AsyncValue<AppUser>.loading()) {
    if (_token != null) {
      loadUser();
    }
  }

  Future<void> loadUser() async {
    state = const AsyncValue<AppUser>.loading();
    try {
      final AppUser user = await _getCurrentUser();
      state = AsyncValue<AppUser>.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue<AppUser>.error(error, stackTrace);
    }
  }
}

final StateNotifierProvider<CurrentUserNotifier, AsyncValue<AppUser>> currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<AppUser>>((Ref ref) {
  final GetCurrentUser getCurrentUser = ref.watch(getCurrentUserProvider);
  final String? token = ref.watch(clerkTokenProvider);
  return CurrentUserNotifier(getCurrentUser, token);
});
