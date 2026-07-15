import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<AppUser> getCurrentUser() async {
    try {
      return await _remoteDataSource.getCurrentUser();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.error is SocketException) {
        throw const NetworkFailure();
      }

      if (e.response != null) {
        final int? statusCode = e.response?.statusCode;
        final dynamic data = e.response?.data;
        String errorMessage = 'An unexpected server error occurred.';

        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'] as String;
        } else if (e.error != null) {
          errorMessage = e.error.toString();
        }

        if (statusCode == 401 || statusCode == 403) {
          throw AuthFailure(errorMessage);
        }
        throw ServerFailure(errorMessage, statusCode: statusCode);
      }

      throw ServerFailure(e.message ?? 'Unknown connection error.');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
