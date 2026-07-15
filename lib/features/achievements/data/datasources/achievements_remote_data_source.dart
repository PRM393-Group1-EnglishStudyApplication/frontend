import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../models/achievement_model.dart';

abstract class AchievementsRemoteDataSource {
  Future<List<AchievementModel>> getAchievements();
  Future<List<AchievementModel>> getMyAchievements();
}

class AchievementsRemoteDataSourceImpl implements AchievementsRemoteDataSource {
  final Dio _dio;

  AchievementsRemoteDataSourceImpl(this._dio);

  @override
  Future<List<AchievementModel>> getAchievements() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/achievements');

    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Empty response body from server.',
      );
    }

    final ApiResponse<List<dynamic>> apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (Object? json) => json as List<dynamic>,
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: apiResponse.message.isNotEmpty ? apiResponse.message : 'Server returned an error.',
      );
    }

    return apiResponse.data!
        .map((dynamic item) => AchievementModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AchievementModel>> getMyAchievements() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/achievements/me');

    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Empty response body from server.',
      );
    }

    final ApiResponse<List<dynamic>> apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (Object? json) => json as List<dynamic>,
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: apiResponse.message.isNotEmpty ? apiResponse.message : 'Server returned an error.',
      );
    }

    return apiResponse.data!
        .map((dynamic item) => AchievementModel.fromUserAchievementJson(item as Map<String, dynamic>))
        .toList();
  }
}
