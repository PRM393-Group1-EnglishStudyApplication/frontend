import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../models/leaderboard_entry_model.dart';

abstract class LeaderboardRemoteDataSource {
  Future<List<LeaderboardEntryModel>> getCurrentLeaderboard();
  Future<LeaderboardEntryModel> getMyLeaderboard();
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  final Dio _dio;

  LeaderboardRemoteDataSourceImpl(this._dio);

  @override
  Future<List<LeaderboardEntryModel>> getCurrentLeaderboard() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/leaderboard');

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
        .map((dynamic item) => LeaderboardEntryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LeaderboardEntryModel> getMyLeaderboard() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/leaderboard/me');

    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Empty response body from server.',
      );
    }

    final ApiResponse<LeaderboardEntryModel> apiResponse = ApiResponse<LeaderboardEntryModel>.fromJson(
      response.data as Map<String, dynamic>,
      (Object? json) => LeaderboardEntryModel.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: apiResponse.message.isNotEmpty ? apiResponse.message : 'Server returned an error.',
      );
    }

    return apiResponse.data!;
  }
}
