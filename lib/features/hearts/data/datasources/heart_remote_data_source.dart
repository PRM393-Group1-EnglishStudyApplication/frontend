import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/heart_model.dart';

abstract class HeartRemoteDataSource {
  Future<HeartModel> getMyHearts();

  Future<HeartModel> refillHearts();
}

class HeartRemoteDataSourceImpl implements HeartRemoteDataSource {
  final Dio _dio;

  HeartRemoteDataSourceImpl(this._dio);

  @override
  Future<HeartModel> getMyHearts() =>
      _request(() => _dio.get<dynamic>('/api/hearts/me'));

  @override
  Future<HeartModel> refillHearts() =>
      _request(() => _dio.post<dynamic>('/api/hearts/refill'));

  Future<HeartModel> _request(
    Future<Response<dynamic>> Function() request,
  ) async {
    final Response<dynamic> response = await request();
    final Object? responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Empty or invalid response body from server.',
      );
    }

    final ApiResponse<HeartModel> apiResponse =
        ApiResponse<HeartModel>.fromJson(
          responseData,
          (Object? json) => HeartModel.fromJson(json as Map<String, dynamic>),
        );

    if (!apiResponse.success || apiResponse.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: apiResponse.message.isNotEmpty
            ? apiResponse.message
            : 'Server returned an error.',
      );
    }

    return apiResponse.data!;
  }
}
