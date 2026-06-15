import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/auth_providers.dart';
import '../screens/sign_in_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  ClerkAuthState? _clerkAuthState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final ClerkAuthState authState = ClerkAuth.of(context);
      if (_clerkAuthState != authState) {
        _clerkAuthState?.removeListener(_onAuthStateChanged);
        _clerkAuthState = authState;
        _clerkAuthState?.addListener(_onAuthStateChanged);
        _onAuthStateChanged();
      }
    } catch (_) {
      // Handle the case where ClerkAuth is not yet in context (during bootstrap)
    }
  }

  @override
  void dispose() {
    _clerkAuthState?.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  Future<void> _onAuthStateChanged() async {
    final ClerkAuthState? authState = _clerkAuthState;
    if (authState == null) return;

    if (authState.isSignedIn) {
      final dynamic tokenObj = await authState.sessionToken();
      if (mounted) {
        ref.read(clerkTokenProvider.notifier).state = tokenObj?.jwt as String?;
      }
    } else {
      if (mounted) {
        ref.read(clerkTokenProvider.notifier).state = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClerkAuthBuilder(
      signedInBuilder: (BuildContext context, ClerkAuthState authState) {
        return widget.child;
      },
      signedOutBuilder: (BuildContext context, ClerkAuthState authState) {
        return const SignInScreen();
      },
    );
  }
}
