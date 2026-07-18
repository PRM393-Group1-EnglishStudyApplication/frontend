import 'package:dio/dio.dart';

import 'package:prm_frontend/core/network/api_response.dart';
import 'package:prm_frontend/features/flashcards/data/models/flashcard_model.dart';
import 'package:prm_frontend/features/flashcards/data/models/review_result_model.dart';

class FlashcardReviewRequest {
  final String vocabularyId;
  final String result; // 'known' | 'unknown'

  const FlashcardReviewRequest({required this.vocabularyId, required this.result});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'vocabulary_id': vocabularyId,
    'result': result,
  };
}

abstract class FlashcardRemoteDataSource {
  Future<FlashcardSessionModel> getSession(FlashcardSource source, {String? lessonId});
  Future<ReviewSubmitResultModel> submitReviews(List<FlashcardReviewRequest> reviews);
  Future<String> getTtsAudioUrl(String text, {String lang = 'en'});
}

class FlashcardRemoteDataSourceImpl implements FlashcardRemoteDataSource {
  final Dio _dio;

  FlashcardRemoteDataSourceImpl(this._dio);

  @override
  Future<FlashcardSessionModel> getSession(FlashcardSource source, {String? lessonId}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/flashcards/session',
        queryParameters: <String, dynamic>{
          'source': source.apiValue,
          if (lessonId != null) 'lessonId': lessonId,
        },
      );

      if (response.data == null) {
        throw Exception('Empty response body from server.');
      }

      final apiResponse = ApiResponse<FlashcardSessionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => FlashcardSessionModel.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message);
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<ReviewSubmitResultModel> submitReviews(List<FlashcardReviewRequest> reviews) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/flashcards/review',
        data: <String, dynamic>{'reviews': reviews.map((r) => r.toJson()).toList()},
      );

      if (response.data == null) {
        throw Exception('Empty response body from server.');
      }

      final apiResponse = ApiResponse<ReviewSubmitResultModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ReviewSubmitResultModel.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message);
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<String> getTtsAudioUrl(String text, {String lang = 'en'}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/tts',
        queryParameters: <String, dynamic>{'text': text, 'lang': lang, 'format': 'link'},
      );

      if (response.data == null) {
        throw Exception('Empty response body from server.');
      }

      final apiResponse = ApiResponse<String>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as Map<String, dynamic>)['audio_url'] as String? ?? '',
      );

      if (!apiResponse.success || apiResponse.data == null || apiResponse.data!.isEmpty) {
        throw Exception(apiResponse.message);
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

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
