import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/heart_status.dart';
import '../../domain/repositories/heart_repository.dart';
import '../datasources/heart_remote_data_source.dart';

class HeartRepositoryImpl implements HeartRepository {
  final HeartRemoteDataSource _remoteDataSource;

  HeartRepositoryImpl(this._remoteDataSource);

  @override
  Future<HeartStatus> getMyHearts() => _run(_remoteDataSource.getMyHearts);

  @override
  Future<HeartStatus> refillHearts() => _run(_remoteDataSource.refillHearts);

  Future<HeartStatus> _run(Future<HeartStatus> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.error is SocketException) {
        throw const NetworkFailure();
      }

      final int? statusCode = error.response?.statusCode;
      final Object? data = error.response?.data;
      final String message =
          data is Map<String, dynamic> && data['message'] != null
          ? data['message'].toString()
          : error.error?.toString() ??
                error.message ??
                'Unable to sync hearts.';

      if (statusCode == 401 || statusCode == 403) {
        throw AuthFailure(message);
      }
      throw ServerFailure(message, statusCode: statusCode);
    }
  }
}
