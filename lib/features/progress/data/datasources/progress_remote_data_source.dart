import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/progress_entry_model.dart';

abstract class ProgressRemoteDataSource {
  Future<List<ProgressEntryModel>> getMyProgress();
  Future<int> getLearnedVocabularyCount();
}

class ProgressRemoteDataSourceImpl implements ProgressRemoteDataSource {
  final Dio _dio;

  ProgressRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ProgressEntryModel>> getMyProgress() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/progress/me',
    );
    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Empty response body from server.',
      );
    }

    final ApiResponse<List<dynamic>> apiResponse =
        ApiResponse<List<dynamic>>.fromJson(
          response.data as Map<String, dynamic>,
          (Object? json) => json as List<dynamic>,
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

    return apiResponse.data!
        .map(
          (dynamic item) =>
              ProgressEntryModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<int> getLearnedVocabularyCount() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/progress/me/vocabulary-count',
    );
    final ApiResponse<Map<String, dynamic>> apiResponse =
        ApiResponse<Map<String, dynamic>>.fromJson(
          response.data as Map<String, dynamic>,
          (Object? json) => json as Map<String, dynamic>,
        );
    if (!apiResponse.success || apiResponse.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: apiResponse.message,
      );
    }
    return (apiResponse.data!['count'] as num?)?.toInt() ?? 0;
  }
}
