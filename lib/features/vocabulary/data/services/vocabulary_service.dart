import 'package:dio/dio.dart';

import '../models/vocabulary_model.dart';

class VocabularyService {
  final Dio _dio;

  const VocabularyService(this._dio);

  Future<List<VocabularyModel>> getVocabularyForLesson(String lessonId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/lessons/$lessonId');
    final lessonData = response.data?['data'] as Map<String, dynamic>?;
    final vocabList = (lessonData?['vocabulary'] as List<dynamic>?) ?? [];
    return vocabList
        .map((e) => VocabularyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
