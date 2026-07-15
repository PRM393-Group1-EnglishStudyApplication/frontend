import 'package:dio/dio.dart';

import '../models/course_model.dart';

class CourseService {
  final Dio _dio;

  const CourseService(this._dio);

  Future<List<CourseModel>> getCourses({String? targetLevel}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/courses',
      queryParameters: targetLevel != null ? {'targetLevel': targetLevel} : null,
    );
    final data = (response.data?['data'] as List<dynamic>?) ?? [];
    return data
        .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CourseModel> getCourse(String courseId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/courses/$courseId');
    final data = response.data?['data'] as Map<String, dynamic>;
    return CourseModel.fromJson(data);
  }
}
