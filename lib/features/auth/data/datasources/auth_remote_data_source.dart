import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<UserModel> getCurrentUser() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/auth/me');
    
    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Empty response body from server.',
      );
    }

    final ApiResponse<UserModel> apiResponse = ApiResponse<UserModel>.fromJson(
      response.data as Map<String, dynamic>,
      (Object? json) => UserModel.fromJson(json as Map<String, dynamic>),
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
