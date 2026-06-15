import 'package:dio/dio.dart';

import '../models/unit_model.dart';

class UnitService {
  final Dio _dio;

  const UnitService(this._dio);

  Future<List<UnitModel>> getUnits(String courseId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/courses/$courseId/units');
    final data = (response.data?['data'] as List<dynamic>?) ?? [];
    return data
        .map((e) => UnitModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
}
