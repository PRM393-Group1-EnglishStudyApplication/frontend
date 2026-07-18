import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../lessons/data/models/course_model.dart';
import '../../../lessons/data/models/exercise_model.dart';
import '../../../lessons/data/models/lesson_model.dart';
import '../../../lessons/data/models/unit_model.dart';

class AdminService {
  final Dio _dio;

  AdminService(this._dio);

  // === Course CRUD ===

  Future<CourseModel> createCourse({
    required String title,
    int languageId = 1,
    String targetLevel = 'beginner',
  }) async {
    final response = await _dio.post<dynamic>(
      '/api/courses',
      data: <String, dynamic>{
        'title': title,
        'language_id': languageId,
        'target_level': targetLevel,
      },
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return CourseModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<CourseModel> updateCourse({
    required String courseId,
    String? title,
    String? targetLevel,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (targetLevel != null) data['target_level'] = targetLevel;

    final response = await _dio.put<dynamic>(
      '/api/courses/$courseId',
      data: data,
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return CourseModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<void> deleteCourse(String courseId) async {
    final response = await _dio.delete<dynamic>('/api/courses/$courseId');
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success) {
      throw Exception(apiResponse.message);
    }
  }

  // === Unit CRUD ===

  Future<UnitModel> createUnit({
    required String courseId,
    required String title,
    required int orderIndex,
  }) async {
    final response = await _dio.post<dynamic>(
      '/api/units',
      data: <String, dynamic>{
        'course_id': courseId,
        'title': title,
        'order_index': orderIndex,
      },
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return UnitModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<UnitModel> updateUnit({
    required String unitId,
    String? title,
    int? orderIndex,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (orderIndex != null) data['order_index'] = orderIndex;

    final response = await _dio.put<dynamic>(
      '/api/units/$unitId',
      data: data,
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return UnitModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<void> deleteUnit(String unitId) async {
    final response = await _dio.delete<dynamic>('/api/units/$unitId');
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success) {
      throw Exception(apiResponse.message);
    }
  }

  // === Lesson CRUD ===

  Future<LessonModel> createLesson({
    required String unitId,
    required String title,
    required int orderIndex,
    int xpReward = 10,
  }) async {
    final response = await _dio.post<dynamic>(
      '/api/lessons',
      data: <String, dynamic>{
        'unit_id': unitId,
        'title': title,
        'order_index': orderIndex,
        'xp_reward': xpReward,
      },
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return LessonModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<LessonModel> updateLesson({
    required String lessonId,
    String? unitId,
    String? title,
    int? orderIndex,
    int? xpReward,
  }) async {
    final data = <String, dynamic>{};
    if (unitId != null) data['unit_id'] = unitId;
    if (title != null) data['title'] = title;
    if (orderIndex != null) data['order_index'] = orderIndex;
    if (xpReward != null) data['xp_reward'] = xpReward;

    final response = await _dio.put<dynamic>(
      '/api/lessons/$lessonId',
      data: data,
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return LessonModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<void> deleteLesson(String lessonId) async {
    final response = await _dio.delete<dynamic>('/api/lessons/$lessonId');
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success) {
      throw Exception(apiResponse.message);
    }
  }

  // === Exercise CRUD ===

  Future<List<ExerciseModel>> getLessonExercises(String lessonId) async {
    final response = await _dio.get<dynamic>('/api/lessons/$lessonId/exercises');
    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as List<dynamic>,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!
        .map((item) => ExerciseModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ExerciseModel> createExercise({
    required String lessonId,
    required String question,
    required String exerciseType,
    required String correctAnswer,
    String? audioUrl,
    List<Map<String, dynamic>>? options,
  }) async {
    final response = await _dio.post<dynamic>(
      '/api/exercises',
      data: <String, dynamic>{
        'lesson_id': lessonId,
        'question': question,
        'exercise_type': exerciseType,
        'correct_answer': correctAnswer,
        if (audioUrl != null) 'audio_url': audioUrl,
        if (options != null) 'options': options,
      },
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return ExerciseModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<ExerciseModel> updateExercise({
    required String exerciseId,
    String? question,
    String? exerciseType,
    String? correctAnswer,
    String? audioUrl,
  }) async {
    final data = <String, dynamic>{};
    if (question != null) data['question'] = question;
    if (exerciseType != null) data['exercise_type'] = exerciseType;
    if (correctAnswer != null) data['correct_answer'] = correctAnswer;
    data['audio_url'] = audioUrl; // Allow null to clear it

    final response = await _dio.put<dynamic>(
      '/api/exercises/$exerciseId',
      data: data,
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return ExerciseModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<void> deleteExercise(String exerciseId) async {
    final response = await _dio.delete<dynamic>('/api/exercises/$exerciseId');
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success) {
      throw Exception(apiResponse.message);
    }
  }

  // === Exercise Options CRUD ===

  Future<ExerciseOptionModel> createOption({
    required String exerciseId,
    required String optionText,
    required bool isCorrect,
  }) async {
    final response = await _dio.post<dynamic>(
      '/api/exercises/$exerciseId/options',
      data: <String, dynamic>{
        'option_text': optionText,
        'is_correct': isCorrect,
      },
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return ExerciseOptionModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<ExerciseOptionModel> updateOption({
    required String optionId,
    required String optionText,
    required bool isCorrect,
  }) async {
    final response = await _dio.put<dynamic>(
      '/api/exercise-options/$optionId',
      data: <String, dynamic>{
        'option_text': optionText,
        'is_correct': isCorrect,
      },
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return ExerciseOptionModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<void> deleteOption(String optionId) async {
    final response = await _dio.delete<dynamic>('/api/exercise-options/$optionId');
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success) {
      throw Exception(apiResponse.message);
    }
  }

  // === Vocabulary CRUD & Lesson association ===

  Future<List<VocabularyModel>> getGlobalVocabulary() async {
    final response = await _dio.get<dynamic>('/api/vocabulary');
    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as List<dynamic>,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!
        .map((item) => VocabularyModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<VocabularyModel> createVocabulary({
    required String word,
    required String meaning,
    required String pronunciation,
    required String exampleSentence,
  }) async {
    final response = await _dio.post<dynamic>(
      '/api/vocabulary',
      data: <String, dynamic>{
        'word': word,
        'meaning': meaning,
        'pronunciation': pronunciation,
        'example_sentence': exampleSentence,
      },
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return VocabularyModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<VocabularyModel> updateVocabulary({
    required String vocabId,
    String? word,
    String? meaning,
    String? pronunciation,
    String? exampleSentence,
  }) async {
    final data = <String, dynamic>{};
    if (word != null) data['word'] = word;
    if (meaning != null) data['meaning'] = meaning;
    if (pronunciation != null) data['pronunciation'] = pronunciation;
    if (exampleSentence != null) data['example_sentence'] = exampleSentence;

    final response = await _dio.put<dynamic>(
      '/api/vocabulary/$vocabId',
      data: data,
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return VocabularyModel.fromJson(apiResponse.data as Map<String, dynamic>);
  }

  Future<void> deleteVocabulary(String vocabId) async {
    final response = await _dio.delete<dynamic>('/api/vocabulary/$vocabId');
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success) {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> attachVocabularyToLesson({
    required String lessonId,
    required String vocabId,
  }) async {
    final response = await _dio.post<dynamic>('/api/lessons/$lessonId/vocabulary/$vocabId');
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success) {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> detachVocabularyFromLesson({
    required String lessonId,
    required String vocabId,
  }) async {
    final response = await _dio.delete<dynamic>('/api/lessons/$lessonId/vocabulary/$vocabId');
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
    if (!apiResponse.success) {
      throw Exception(apiResponse.message);
    }
  }

  Future<ImportReportModel> importExercises({
    required String lessonId,
    required List<int> fileBytes,
    required String fileName,
    required bool dryRun,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post<dynamic>(
        '/api/lessons/$lessonId/exercises/import',
        queryParameters: {'dryRun': dryRun.toString()},
        data: formData,
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message);
      }

      return ImportReportModel.fromJson(apiResponse.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data.containsKey('success') && data['success'] == false) {
          if (data.containsKey('details')) {
            return ImportReportModel.fromJson({
              'dryRun': dryRun,
              'errors': data['details'],
              'warnings': <dynamic>[],
              'preview': <dynamic>[],
              'totalRows': 0,
              'validRows': 0,
              'inserted': 0,
            });
          } else {
            throw Exception(data['message'] ?? 'Import thất bại');
          }
        }
      }
      rethrow;
    }
  }

  Future<List<int>> downloadImportTemplate() async {
    final response = await _dio.get<List<int>>(
      '/api/exercises/import/template.csv',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}

final Provider<AdminService> adminServiceProvider = Provider<AdminService>((Ref ref) {
  final dio = ref.watch(authDioProvider);
  return AdminService(dio);
});

// Cache loader for a lesson's exercises
final FutureProviderFamily<List<ExerciseModel>, String> lessonExercisesProvider =
    FutureProvider.family<List<ExerciseModel>, String>((Ref ref, String lessonId) async {
  final service = ref.watch(adminServiceProvider);
  return service.getLessonExercises(lessonId);
});

// Cache loader for global vocabulary
final FutureProvider<List<VocabularyModel>> globalVocabularyProvider =
    FutureProvider<List<VocabularyModel>>((Ref ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.getGlobalVocabulary();
});
