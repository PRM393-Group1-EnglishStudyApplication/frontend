import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../models/course_model.dart';
import '../models/unit_model.dart';
import '../models/lesson_model.dart';
import '../models/exercise_model.dart';

abstract class LessonsRemoteDataSource {
  Future<List<CourseModel>> getCourses();
  Future<List<UnitModel>> getUnits(String courseId);
  Future<List<LessonModel>> getLessons(String unitId);
  Future<LessonDetailModel> getLessonDetail(String lessonId);
  Future<LessonSubmissionResult> submitLesson(String lessonId, List<Map<String, dynamic>> answers);
  Future<List<VocabularyModel>> getFavoriteVocabularies();
  Future<void> addFavoriteVocabulary(String vocabId);
  Future<void> removeFavoriteVocabulary(String vocabId);
}

class LessonsRemoteDataSourceImpl implements LessonsRemoteDataSource {
  final Dio _dio;

  LessonsRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CourseModel>> getCourses() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/courses');
    if (response.data == null) throw Exception('Null response body');
    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as List<dynamic>,
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!.map((item) => CourseModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<UnitModel>> getUnits(String courseId) async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/courses/$courseId/units');
    if (response.data == null) throw Exception('Null response body');
    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as List<dynamic>,
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!.map((item) => UnitModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<LessonModel>> getLessons(String unitId) async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/units/$unitId/lessons');
    if (response.data == null) throw Exception('Null response body');
    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as List<dynamic>,
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!.map((item) => LessonModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<LessonDetailModel> getLessonDetail(String lessonId) async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/lessons/$lessonId');
    if (response.data == null) throw Exception('Null response body');
    final apiResponse = ApiResponse<LessonDetailModel>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LessonDetailModel.fromJson(json as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!;
  }  @override
  Future<LessonSubmissionResult> submitLesson(String lessonId, List<Map<String, dynamic>> answers) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/lessons/$lessonId/submit',
      data: <String, dynamic>{'answers': answers},
    );
    if (response.data == null) throw Exception('Null response body');
    final apiResponse = ApiResponse<LessonSubmissionResult>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LessonSubmissionResult.fromJson(json as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!;
  }

  @override
  Future<List<VocabularyModel>> getFavoriteVocabularies() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/api/favorites/me');
    if (response.data == null) throw Exception('Null response body');
    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as List<dynamic>,
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!.map((item) {
      final map = item as Map<String, dynamic>;
      final vocabJson = map['vocabulary'] as Map<String, dynamic>?;
      return vocabJson != null ? VocabularyModel.fromJson(vocabJson) : null;
    }).whereType<VocabularyModel>().toList();
  }

  @override
  Future<void> addFavoriteVocabulary(String vocabId) async {
    final Response<dynamic> response = await _dio.post<dynamic>('/api/favorites/$vocabId');
    if (response.data == null) throw Exception('Null response body');
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success) throw Exception(apiResponse.message);
  }

  @override
  Future<void> removeFavoriteVocabulary(String vocabId) async {
    final Response<dynamic> response = await _dio.delete<dynamic>('/api/favorites/$vocabId');
    if (response.data == null) throw Exception('Null response body');
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success) throw Exception(apiResponse.message);
  }
}
