import 'package:dio/dio.dart';

import 'package:prm_frontend/core/network/api_response.dart';
import 'package:prm_frontend/features/explanations/data/models/explanation_model.dart';

abstract class ExplanationRemoteDataSource {
  Future<ExplanationModel> explainWrongAnswer(String exerciseId, String userAnswer);
}

class ExplanationRemoteDataSourceImpl implements ExplanationRemoteDataSource {
  final Dio _dio;

  ExplanationRemoteDataSourceImpl(this._dio);

  @override
  Future<ExplanationModel> explainWrongAnswer(String exerciseId, String userAnswer) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/exercises/$exerciseId/explain',
        data: <String, dynamic>{'user_answer': userAnswer},
      );

      if (response.data == null) {
        throw Exception('Empty response body from server.');
      }

      final apiResponse = ApiResponse<ExplanationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ExplanationModel.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message);
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Backend tra ve { success:false, message, details } ngay ca khi loi (400/401/429/502/503)
  // -> uu tien lay message tu do de hien thi thong bao than thien bang tieng Viet.
  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.';
  }
}
