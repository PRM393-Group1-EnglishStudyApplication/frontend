import 'package:dio/dio.dart';

import 'api_endpoints.dart';

class ApiClient {
  ApiClient._();

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      // AI responses can take longer than regular REST requests.
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
      headers: <String, String>{'Content-Type': 'application/json'},
    ),
  );
}
