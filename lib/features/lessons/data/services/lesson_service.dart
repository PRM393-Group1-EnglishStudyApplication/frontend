import 'package:dio/dio.dart';

import '../models/lesson_model.dart';

class LessonService {
  final Dio _dio;

  const LessonService(this._dio);

  Future<List<LessonModel>> getLessons(String unitId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/units/$unitId/lessons');
    final data = (response.data?['data'] as List<dynamic>?) ?? [];
    return data
        .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
}
