import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class UserApiService {
  final Dio _dio;

  UserApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  Future<List<dynamic>> getUsers() async {
    final Response<dynamic> response = await _dio.get<dynamic>(ApiEndpoints.users);
    final dynamic data = response.data;

    if (data is List<dynamic>) {
      return data;
    }

    return <dynamic>[];
  }
}
