import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../lessons/data/models/exercise_model.dart';

abstract class PracticeRemoteDataSource {
  Future<List<ExerciseModel>> getPracticePack();
  Future<LessonSubmissionResult> submitPracticePack(List<Map<String, dynamic>> answers);
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

    final apiResponse = ApiResponse<LessonSubmissionResult>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LessonSubmissionResult.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }

    return apiResponse.data!;
  }
}
