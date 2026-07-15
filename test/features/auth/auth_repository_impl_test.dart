import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/core/errors/failures.dart';
import 'package:prm_frontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:prm_frontend/features/auth/data/models/user_model.dart';
import 'package:prm_frontend/features/auth/data/repositories/auth_repository_impl.dart';

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  UserModel? user;
  Object? exception;

  @override
  Future<UserModel> getCurrentUser() async {
    if (exception != null) {
      throw exception!;
    }
    if (user != null) {
      return user!;
    }
    throw Exception('No fake data provided');
  }
}

void main() {
  late FakeAuthRemoteDataSource fakeDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    fakeDataSource = FakeAuthRemoteDataSource();
    repository = AuthRepositoryImpl(fakeDataSource);
  });

  group('AuthRepositoryImpl tests', () {
    const testUser = UserModel(
      id: 'id123',
      email: 'jane@example.com',
      totalXp: 10,
      currentLevel: 'beginner',
      streakCount: 1,
    );

    test('returns AppUser on successful remote call', () async {
      fakeDataSource.user = testUser;

      final result = await repository.getCurrentUser();

      expect(result, testUser);
    });

    test('throws NetworkFailure on connection timeout', () async {
      fakeDataSource.exception = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        () => repository.getCurrentUser(),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('throws NetworkFailure on SocketException', () async {
      fakeDataSource.exception = DioException(
        requestOptions: RequestOptions(path: ''),
        error: const SocketException('No Internet'),
      );

      expect(
        () => repository.getCurrentUser(),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('throws AuthFailure on 401 Unauthorized response', () async {
      fakeDataSource.exception = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 401,
          data: {'message': 'Please login first'},
        ),
      );

      expect(
        () => repository.getCurrentUser(),
        throwsA(isA<AuthFailure>().having((e) => e.message, 'message', 'Please login first')),
      );
    });

    test('throws ServerFailure on other HTTP status codes', () async {
      fakeDataSource.exception = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 500,
          data: {'message': 'Internal Server Error'},
        ),
      );

      expect(
        () => repository.getCurrentUser(),
        throwsA(isA<ServerFailure>().having((e) => e.message, 'message', 'Internal Server Error')),
      );
    });
  });
}
