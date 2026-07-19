import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'deep_link.dart';

/// Trạng thái quyền thông báo của hệ thống, gộp lại cho cả Android và iOS.
enum PushPermission { granted, denied, notDetermined, unsupported }

/// Chạy trong isolate riêng khi app đang ở nền hoặc đã tắt hẳn.
///
/// Phải là hàm top-level và có `@pragma('vm:entry-point')`, nếu không bản
/// release sẽ tree-shake mất và push nền im lặng không chạy.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Isolate này không dùng chung state với app nên không có gì để cập nhật.
  // Hệ thống tự hiện notification; việc điều hướng xảy ra khi user bấm vào
  // (onMessageOpenedApp / getInitialMessage). Giữ handler để FCM đánh thức app
  // và để chỗ mở rộng sau này (v2: đồng bộ badge, cache...).
  debugPrint('PushService: background message ${message.messageId}');
}

/// Bọc toàn bộ FCM + local notification.
///
/// Mọi thao tác đều nuốt lỗi (NFR-3): thiết bị không có Google Play Services,
/// user từ chối quyền, hay chưa cấu hình Firebase đều không được làm sập app —
/// các tính năng còn lại phải chạy bình thường.
class PushService {
  /// Phải trùng với `channelId` backend gửi trong `android.notification.channel_id`.
  static const String androidChannelId = 'study_reminders';

  static final PushService instance = PushService._();

  PushService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final StreamController<PendingDeepLink> _openedController =
      StreamController<PendingDeepLink>.broadcast();

  bool _initialized = false;
  bool _available = false;

  /// `true` khi Firebase khởi tạo thành công và có thể lấy token.
  bool get isAvailable => _available;

  /// Phát ra mỗi lần user bấm vào một thông báo, ở bất kỳ trạng thái nào của app.
  Stream<PendingDeepLink> get onOpened => _openedController.stream;

  /// Token FCM đổi khi app được cài lại hoặc Firebase xoay vòng token.
  Stream<String> get onTokenRefresh =>
      _available ? FirebaseMessaging.instance.onTokenRefresh : const Stream<String>.empty();

  /// Khởi tạo Firebase + kênh thông báo. Gọi trong `main()` trước `runApp`.
  ///
  /// Cố ý **không** xin quyền ở đây: theo FR-2, chỉ hỏi sau lần đăng nhập
  /// thành công đầu tiên, không phải ngay khi mở app.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      // Không truyền options: Firebase đọc cấu hình native (android/app/google-services.json,
      // ios/Runner/GoogleService-Info.plist). Chưa chạy `flutterfire configure` thì lệnh này
      // ném lỗi và app rơi về chế độ không có push thay vì crash (NFR-3).
      await Firebase.initializeApp();
      await _setupLocalNotifications();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

      // iOS không tự hiện banner khi app đang mở nếu ta tự xử lý bằng local
      // notification -> tắt để tránh hiện hai lần.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      _available = true;
    } catch (error) {
      debugPrint('PushService: khởi tạo thất bại, bỏ qua push. $error');
      _available = false;
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Quyền iOS xin riêng qua FirebaseMessaging.requestPermission (FR-2),
    // nên ở đây tắt hết để không bật hộp thoại sớm.
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: darwinSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final PendingDeepLink? link = decodeDeepLinkPayload(response.payload);
        if (link != null) {
          _openedController.add(link);
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      androidChannelId,
      'Nhắc học tập',
      description: 'Nhắc vào học hằng ngày để giữ chuỗi streak.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// FCM không tự hiện banner khi app đang mở -> phải tự hiện (FR-5).
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) {
      return;
    }

    try {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannelId,
            'Nhắc học tập',
            channelDescription: 'Nhắc vào học hằng ngày để giữ chuỗi streak.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: encodeDeepLinkPayload(message.data),
      );
    } catch (error) {
      debugPrint('PushService: không hiện được thông báo foreground. $error');
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final PendingDeepLink? link = parseDeepLink(message.data);
    if (link != null) {
      _openedController.add(link);
    }
  }

  /// Thông báo đã mở app từ trạng thái tắt hẳn (terminated).
  ///
  /// Chỉ trả về giá trị đúng một lần — FCM tự xoá sau lần đọc đầu tiên.
  Future<PendingDeepLink?> takeInitialDeepLink() async {
    if (!_available) {
      return null;
    }
    try {
      final RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();
      return message == null ? null : parseDeepLink(message.data);
    } catch (error) {
      debugPrint('PushService: không đọc được initial message. $error');
      return null;
    }
  }

  /// Xin quyền thông báo (Android 13+ POST_NOTIFICATIONS, iOS requestPermission).
  Future<PushPermission> requestPermission() async {
    if (!_available) {
      return PushPermission.unsupported;
    }
    try {
      final NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission();
      return _toPermission(settings.authorizationStatus);
    } catch (error) {
      debugPrint('PushService: xin quyền thất bại. $error');
      return PushPermission.unsupported;
    }
  }

  /// Đọc trạng thái quyền hiện tại mà không bật hộp thoại.
  Future<PushPermission> currentPermission() async {
    if (!_available) {
      return PushPermission.unsupported;
    }
    try {
      final NotificationSettings settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return _toPermission(settings.authorizationStatus);
    } catch (error) {
      debugPrint('PushService: đọc quyền thất bại. $error');
      return PushPermission.unsupported;
    }
  }

  PushPermission _toPermission(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return PushPermission.granted;
      case AuthorizationStatus.denied:
        return PushPermission.denied;
      case AuthorizationStatus.notDetermined:
        return PushPermission.notDetermined;
    }
  }

  Future<String?> getToken() async {
    if (!_available) {
      return null;
    }
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('PushService: lấy token thất bại. $error');
      return null;
    }
  }

  /// Xoá token khỏi thiết bị. Dùng khi đăng xuất để máy không còn nhận
  /// nhắc của tài khoản cũ ngay cả khi lệnh xoá phía server thất bại.
  Future<void> deleteToken() async {
    if (!_available) {
      return;
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('PushService: xoá token thất bại. $error');
    }
  }
}
