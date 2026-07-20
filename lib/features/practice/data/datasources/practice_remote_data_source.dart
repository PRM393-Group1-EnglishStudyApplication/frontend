import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../lessons/domain/entities/exercise_entities.dart';
import '../../../lessons/data/models/exercise_model.dart';

abstract class PracticeRemoteDataSource {
  Future<List<ExerciseModel>> getPracticePack();
  Future<LessonSubmissionResult> submitPracticePack(List<Map<String, dynamic>> answers);
  Future<WrongAnswerPack> getWrongAnswerPack();
  Future<WrongAnswerReviewResult> submitWrongAnswerReview(
    List<Map<String, dynamic>> answers,
  );
}

class PracticeRemoteDataSourceImpl implements PracticeRemoteDataSource {
  final Dio _dio;

  PracticeRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ExerciseModel>> getPracticePack() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/practice/pack');

    if (response.data == null) {
      throw Exception('Empty response body from server.');
    }

    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as List<dynamic>,
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }

    return apiResponse.data!
        .map((dynamic item) => ExerciseModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LessonSubmissionResult> submitPracticePack(List<Map<String, dynamic>> answers) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/practice/submit',
      data: <String, dynamic>{'answers': answers},
    );

    if (response.data == null) {
      throw Exception('Empty response body from server.');
    }

    final apiResponse = ApiResponse<LessonSubmissionResultModel>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LessonSubmissionResultModel.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }

    return apiResponse.data!;
  }

  @override
  Future<WrongAnswerPack> getWrongAnswerPack() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/practice/wrong-answers',
      queryParameters: <String, dynamic>{'limit': 10},
    );
    final apiResponse = ApiResponse<WrongAnswerPackModel>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WrongAnswerPackModel.fromJson(json as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  @override
  Future<WrongAnswerReviewResult> submitWrongAnswerReview(
    List<Map<String, dynamic>> answers,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/practice/wrong-answers/submit',
      data: <String, dynamic>{'answers': answers},
    );
    final apiResponse = ApiResponse<WrongAnswerReviewResultModel>.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          WrongAnswerReviewResultModel.fromJson(json as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }
}
