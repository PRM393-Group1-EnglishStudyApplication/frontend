import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/core/network/api_response.dart';

void main() {
  group('ApiResponse parsing tests', () {
    test('Parse successful response with valid data', () {
      final json = {
        'success': true,
        'message': 'Loaded successfully',
        'data': 'test_payload',
      };

      final response = ApiResponse<String>.fromJson(
        json,
        (data) => data as String,
      );

      expect(response.success, isTrue);
      expect(response.message, 'Loaded successfully');
      expect(response.data, 'test_payload');
    });

    test('Parse failed response with null data', () {
      final json = {
        'success': false,
        'message': 'Unauthorized access',
        'data': null,
      };

      final response = ApiResponse<String>.fromJson(
        json,
        (data) => data as String,
      );

      expect(response.success, isFalse);
      expect(response.message, 'Unauthorized access');
      expect(response.data, null);
    });
  });
}
