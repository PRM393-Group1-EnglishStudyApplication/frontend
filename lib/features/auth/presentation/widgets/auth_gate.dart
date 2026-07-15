import 'dart:async';
import 'package:clerk_auth/clerk_auth.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      }
    } catch (e) {
      print('AuthGate: error getting session token: $e');
    }
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
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
        Future.microtask(() {
          if (mounted) {
            ref.read(clerkTokenProvider.notifier).state = null;
          }
        });
        return const OnboardingWizard();
      },
    );
  }
}

