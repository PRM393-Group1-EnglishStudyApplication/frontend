import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/notifications/deep_link.dart';
import '../../../../core/notifications/push_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/notifications_remote_data_source.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/notifications_repository.dart';

/// Deep-link đang chờ điều hướng. `HomePage` tiêu thụ rồi tự set lại `null`.
///
/// Tách khỏi `PushService` vì thông báo hay đến trước khi `AuthGate` xác thực
/// xong — giữ ở đây để không mất đích đến (FR-7).
final StateProvider<PendingDeepLink?> pendingDeepLinkProvider =
    StateProvider<PendingDeepLink?>((Ref ref) => null);

final Provider<PushService> pushServiceProvider =
    Provider<PushService>((Ref ref) => PushService.instance);

final Provider<NotificationsRemoteDataSource> notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((Ref ref) {
  final Dio dio = ref.watch(authDioProvider);
  return NotificationsRemoteDataSourceImpl(dio);
});

final Provider<NotificationsRepository> notificationsRepositoryProvider =
    Provider<NotificationsRepository>((Ref ref) {
  return NotificationsRepositoryImpl(ref.watch(notificationsRemoteDataSourceProvider));
});

/// Nối các nguồn deep-link (bấm thông báo lúc app mở/nền/tắt hẳn) vào
/// [pendingDeepLinkProvider]. Đọc provider này một lần ở gốc cây widget.
final Provider<void> deepLinkListenerProvider = Provider<void>((Ref ref) {
  final PushService pushService = ref.watch(pushServiceProvider);

  final StreamSubscription<PendingDeepLink> subscription =
      pushService.onOpened.listen((PendingDeepLink link) {
    ref.read(pendingDeepLinkProvider.notifier).state = link;
  });
  ref.onDispose(subscription.cancel);

  // Trạng thái terminated: thông báo chính là thứ đã mở app.
  unawaited(pushService.takeInitialDeepLink().then((PendingDeepLink? link) {
    if (link != null) {
      ref.read(pendingDeepLinkProvider.notifier).state = link;
    }
  }));
});

/// Vòng đời device token gắn với phiên đăng nhập (FR-3).
class DeviceTokenSync {
  static const String _permissionAskedKey = 'notification_permission_asked';
  static const String _pendingUnregisterKey = 'notification_pending_unregister_token';

  final NotificationsRepository _repository;
  final PushService _pushService;

  DeviceTokenSync(this._repository, this._pushService);

  String get _platform {
    if (kIsWeb) {
      return 'web';
    }
    return Platform.isIOS ? 'ios' : 'android';
  }

  /// Gọi sau khi đăng nhập thành công.
  ///
  /// Lần đăng nhập đầu tiên sẽ bật hộp thoại xin quyền (FR-2); các lần sau chỉ
  /// đọc trạng thái quyền để không làm phiền lại.
  Future<void> onSignedIn() async {
    if (!_pushService.isAvailable) {
      return;
    }

    try {
      await _retryPendingUnregister();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool asked = prefs.getBool(_permissionAskedKey) ?? false;

      PushPermission permission =
          asked ? await _pushService.currentPermission() : await _pushService.requestPermission();
      if (!asked) {
        await prefs.setBool(_permissionAskedKey, true);
      }

      if (permission != PushPermission.granted) {
        return;
      }

      final String? token = await _pushService.getToken();
      if (token != null) {
        await _repository.registerDeviceToken(token: token, platform: _platform);
      }
    } catch (error) {
      // Không đăng ký được token chỉ làm mất tính năng nhắc, không được chặn
      // người dùng vào app (NFR-3).
      debugPrint('DeviceTokenSync: đăng ký token thất bại. $error');
    }
  }

  /// Token đổi khi cài lại app hoặc Firebase xoay vòng -> đăng ký lại.
  Future<void> onTokenRefreshed(String token) async {
    try {
      await _repository.registerDeviceToken(token: token, platform: _platform);
    } catch (error) {
      debugPrint('DeviceTokenSync: đăng ký lại token thất bại. $error');
    }
  }

  /// Gọi trước khi xoá phiên đăng nhập, để máy không nhận nhắc của tài khoản cũ.
  Future<void> onSignedOut() async {
    if (!_pushService.isAvailable) {
      return;
    }

    final String? token = await _pushService.getToken();
    if (token == null) {
      return;
    }

    try {
      await _repository.unregisterDeviceToken(token);
    } catch (error) {
      // Đăng xuất lúc mất mạng: ghi cờ lại, lần đăng nhập sau sẽ dọn.
      debugPrint('DeviceTokenSync: xoá token phía server thất bại, sẽ thử lại. $error');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingUnregisterKey, token);
    }

    // Xoá token trên máy dù server có xoá được hay không: token mới sẽ được cấp
    // ở lần đăng nhập sau, nên tài khoản cũ chắc chắn không còn nhận nhắc.
    await _pushService.deleteToken();
  }

  Future<void> _retryPendingUnregister() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? pending = prefs.getString(_pendingUnregisterKey);
    if (pending == null || pending.isEmpty) {
      return;
    }
    try {
      await _repository.unregisterDeviceToken(pending);
      await prefs.remove(_pendingUnregisterKey);
    } catch (error) {
      debugPrint('DeviceTokenSync: vẫn chưa xoá được token cũ. $error');
    }
  }
}

final Provider<DeviceTokenSync> deviceTokenSyncProvider = Provider<DeviceTokenSync>((Ref ref) {
  return DeviceTokenSync(
    ref.watch(notificationsRepositoryProvider),
    ref.watch(pushServiceProvider),
  );
});

class ReminderSettingsState {
  final ReminderSettings settings;
  final PushPermission permission;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const ReminderSettingsState({
    required this.settings,
    required this.permission,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  /// Bật nhắc nhưng hệ thống chặn thông báo -> phải hướng dẫn user mở Cài đặt (FR-2).
  bool get needsSystemPermission =>
      settings.enabled && permission != PushPermission.granted;

  ReminderSettingsState copyWith({
    ReminderSettings? settings,
    PushPermission? permission,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return ReminderSettingsState(
      settings: settings ?? this.settings,
      permission: permission ?? this.permission,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReminderSettingsNotifier extends StateNotifier<ReminderSettingsState> {
  final NotificationsRepository _repository;
  final PushService _pushService;

  ReminderSettingsNotifier(this._repository, this._pushService)
      : super(ReminderSettingsState(
          settings: ReminderSettings.fallback(),
          permission: PushPermission.notDetermined,
          isLoading: true,
        )) {
    unawaited(load());
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ReminderSettings settings = await _repository.getReminderSettings();
      state = state.copyWith(
        settings: settings,
        permission: await _pushService.currentPermission(),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        permission: await _pushService.currentPermission(),
        error: 'Không tải được cài đặt nhắc nhở. Kéo xuống để thử lại.',
      );
    }
  }

  /// Đọc lại quyền hệ thống, dùng khi quay lại app từ màn Cài đặt.
  Future<void> refreshPermission() async {
    state = state.copyWith(permission: await _pushService.currentPermission());
  }

  Future<void> setEnabled(bool enabled) async {
    // Bật nhắc mà chưa có quyền thì xin luôn, đỡ bắt user tự mò vào Cài đặt.
    if (enabled && state.permission != PushPermission.granted) {
      final PushPermission permission = await _pushService.requestPermission();
      state = state.copyWith(permission: permission);
    }
    await _save(state.settings.copyWith(enabled: enabled));
  }

  Future<void> setTime(int hour, int minute) {
    final String time =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return _save(state.settings.copyWith(time: time));
  }

  Future<void> _save(ReminderSettings next) async {
    // Cập nhật giao diện trước cho mượt; lỗi thì trả lại giá trị cũ.
    final ReminderSettings previous = state.settings;
    state = state.copyWith(settings: next, isSaving: true, clearError: true);

    try {
      // Luôn gửi kèm múi giờ hiện tại của máy: user đi công tác lệch múi giờ
      // thì giờ nhắc vẫn đúng theo giờ họ đang sống.
      final ReminderSettings saved = await _repository.updateReminderSettings(
        next.copyWith(tzOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes),
      );
      state = state.copyWith(settings: saved, isSaving: false);
    } catch (error) {
      state = state.copyWith(
        settings: previous,
        isSaving: false,
        error: 'Lưu cài đặt thất bại. Kiểm tra kết nối rồi thử lại.',
      );
    }
  }

  /// FR-10: nút gửi thử để kiểm tra thiết bị nhận được push.
  Future<bool> sendTestNotification() async {
    try {
      await _repository.sendTestNotification();
      return true;
    } catch (error) {
      state = state.copyWith(error: 'Không gửi được thông báo thử.');
      return false;
    }
  }
}

final StateNotifierProvider<ReminderSettingsNotifier, ReminderSettingsState>
    reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettingsState>((Ref ref) {
  return ReminderSettingsNotifier(
    ref.watch(notificationsRepositoryProvider),
    ref.watch(pushServiceProvider),
  );
});
