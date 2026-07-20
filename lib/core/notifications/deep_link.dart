import 'dart:convert';

/// Đích điều hướng khi người dùng bấm vào thông báo.
///
/// Backend gửi kèm `data.route` trong payload (xem §6 của REQUIREMENT_6).
/// Giá trị lạ (do backend v2 thêm loại mới mà app chưa cập nhật) rơi vào
/// [DeepLinkRoute.unknown] — app chỉ mở lên chứ không điều hướng đi đâu.
enum DeepLinkRoute { learn, practice, lesson, unknown }

/// Một lần bấm thông báo đang chờ được xử lý.
///
/// Thông báo có thể đến trước khi app xác thực xong (nhất là khi app bị tắt hẳn),
/// nên đích đến được giữ lại ở đây và tiêu thụ sau khi `AuthGate` xác thực xong.
class PendingDeepLink {
  final String type;
  final DeepLinkRoute route;
  final String? lessonId;

  const PendingDeepLink({
    required this.type,
    required this.route,
    this.lessonId,
  });

  /// Chỉ số tab tương ứng trên `HomePage`, `null` nếu không phải điều hướng theo tab.
  int? get tabIndex {
    switch (route) {
      case DeepLinkRoute.learn:
      case DeepLinkRoute.lesson:
        return 0;
      case DeepLinkRoute.practice:
        return 1;
      case DeepLinkRoute.unknown:
        return null;
    }
  }

  @override
  String toString() => 'PendingDeepLink(type: $type, route: $route, lessonId: $lessonId)';
}

DeepLinkRoute _parseRoute(String? raw) {
  switch (raw) {
    case 'learn':
      return DeepLinkRoute.learn;
    case 'practice':
      return DeepLinkRoute.practice;
    case 'lesson':
      return DeepLinkRoute.lesson;
    default:
      return DeepLinkRoute.unknown;
  }
}

/// Đọc data payload của FCM thành [PendingDeepLink].
///
/// FCM ràng buộc mọi value trong `data` phải là string, nhưng payload đi qua
/// nhiều đường (FCM, local notification, isolate nền) nên vẫn ép kiểu phòng hờ.
/// Trả `null` khi payload rỗng — không có gì để điều hướng.
PendingDeepLink? parseDeepLink(Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) {
    return null;
  }

  final String type = (data['type'] as Object?)?.toString() ?? '';
  final DeepLinkRoute route = _parseRoute((data['route'] as Object?)?.toString());
  final String rawLessonId = (data['lesson_id'] as Object?)?.toString() ?? '';

  // route 'lesson' mà thiếu lesson_id thì coi như chỉ mở tab Learn.
  if (route == DeepLinkRoute.lesson && rawLessonId.isEmpty) {
    return PendingDeepLink(type: type, route: DeepLinkRoute.learn);
  }

  return PendingDeepLink(
    type: type,
    route: route,
    lessonId: rawLessonId.isEmpty ? null : rawLessonId,
  );
}

/// Đóng gói data payload để nhét vào `payload` của local notification
/// (foreground) rồi đọc lại khi user bấm vào.
String encodeDeepLinkPayload(Map<String, dynamic> data) => jsonEncode(data);

PendingDeepLink? decodeDeepLinkPayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    return null;
  }
  try {
    final Object? decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return parseDeepLink(decoded);
    }
  } catch (_) {
    // Payload hỏng không đáng để làm phiền user - coi như không có deep-link.
  }
  return null;
}
