import 'package:dio/dio.dart';

import 'api_endpoints.dart';

class ApiClient {
  ApiClient._();

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
    ),
  );
}
