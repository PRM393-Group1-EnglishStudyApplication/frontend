import 'dart:async';
import 'package:clerk_auth/clerk_auth.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../onboarding/presentation/screens/onboarding_wizard.dart';
import '../providers/auth_providers.dart';

class AuthGate extends ConsumerStatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  StreamSubscription<SessionToken>? _tokenSubscription;
  ClerkAuthState? _subscribedAuthState;

  /// Device token đã đăng ký cho phiên hiện tại chưa. Cần cờ này vì
  /// signedInBuilder/signedOutBuilder chạy lại mỗi lần rebuild, còn việc
  /// đăng ký/huỷ token chỉ được chạy đúng một lần mỗi phiên (FR-3).
  bool _pushSessionActive = false;
  StreamSubscription<String>? _fcmTokenSubscription;

  @override
  void initState() {
    super.initState();
    // Bắt đầu lắng nghe deep-link ngay: thông báo mở app từ trạng thái tắt hẳn
    // phải được giữ lại trước khi xác thực xong (FR-7).
    ref.read(deepLinkListenerProvider);
  }

  void _subscribeToTokenStream(ClerkAuthState authState) {
    // Only subscribe once per auth state instance
    if (_subscribedAuthState == authState) return;

    _tokenSubscription?.cancel();
    _subscribedAuthState = authState;

    _tokenSubscription = authState.sessionTokenStream.listen((SessionToken token) {
      print('AuthGate: sessionTokenStream refreshed token');
      if (mounted) {
        ref.read(clerkTokenProvider.notifier).state = token.jwt;
      }
    });
  }

  Future<void> _syncToken(ClerkAuthState authState) async {
    // 1. Try synchronous extraction first (fastest)
    final String? syncJwt = authState.session?.lastActiveToken?.jwt;
    if (syncJwt != null) {
      print('AuthGate: sync jwt found, setting token');
      Future.microtask(() {
        if (mounted) {
          ref.read(clerkTokenProvider.notifier).state = syncJwt;
          _activatePush();
        }
      });
      return;
    }

    // 2. Fall back to async fetch
    try {
      final SessionToken token = await authState.sessionToken();
      print('AuthGate: async sessionToken retrieved');
      if (mounted) {
        ref.read(clerkTokenProvider.notifier).state = token.jwt;
        _activatePush();
      }
    } catch (e) {
      print('AuthGate: error getting session token: $e');
    }
  }

  /// Đăng ký device token cho phiên vừa đăng nhập.
  ///
  /// Gọi sau khi JWT đã vào Riverpod, vì Dio lấy token từ đó cho mỗi request —
  /// gọi sớm hơn thì request đăng ký token sẽ đi mà không có Authorization.
  void _activatePush() {
    if (_pushSessionActive) {
      return;
    }
    _pushSessionActive = true;

    final DeviceTokenSync sync = ref.read(deviceTokenSyncProvider);
    unawaited(sync.onSignedIn());

    _fcmTokenSubscription?.cancel();
    _fcmTokenSubscription = ref
        .read(pushServiceProvider)
        .onTokenRefresh
        .listen((String token) => unawaited(sync.onTokenRefreshed(token)));
  }

  /// Huỷ device token trước khi xoá phiên, để thiết bị không còn nhận
  /// nhắc của tài khoản vừa đăng xuất (FR-3, US-5).
  Future<void> _deactivatePush() async {
    if (!_pushSessionActive) {
      return;
    }
    _pushSessionActive = false;

    await _fcmTokenSubscription?.cancel();
    _fcmTokenSubscription = null;

    // Chạy trước khi xoá clerkTokenProvider: request DELETE vẫn cần Authorization.
    await ref.read(deviceTokenSyncProvider).onSignedOut();
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _fcmTokenSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClerkAuthBuilder(
      signedInBuilder: (BuildContext context, ClerkAuthState authState) {
        // This callback is the reliable signal that the user IS signed in.
        // ClerkAuthBuilder checks auth.client.user before invoking this.
        print('AuthGate: signedInBuilder invoked, user is signed in');

        // Subscribe to token refresh stream
        _subscribeToTokenStream(authState);

        // Sync the token into Riverpod
        _syncToken(authState);

        return widget.child;
      },
      signedOutBuilder: (BuildContext context, ClerkAuthState authState) {
        // Clear the token when signed out
        Future.microtask(() async {
          if (!mounted) {
            return;
          }
          await _deactivatePush();
          if (mounted) {
            ref.read(clerkTokenProvider.notifier).state = null;
          }
        });
        return const OnboardingWizard();
      },
    );
  }
}

