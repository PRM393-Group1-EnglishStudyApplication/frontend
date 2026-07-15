import 'dart:io';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/utils/clerk_file_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../routes/app_router.dart';

class NoopClerkFileCache implements ClerkFileCache {
  const NoopClerkFileCache();

  @override
  Future<void> initialize() async {}

  @override
  void terminate() {}

  @override
  Stream<File> stream(
    Uri uri, {
    Duration ttl = ClerkFileCache.defaultTTL,
    Map<String, String>? headers,
  }) {
    return const Stream<File>.empty();
  }
}

class AppClerkAuthConfig extends ClerkAuthConfig {
  @override
  final clerk.HttpService httpService;

  AppClerkAuthConfig({
    required String publishableKey,
    clerk.HttpService? httpService,
    Widget? loading,
  }) : httpService = httpService ?? const clerk.DefaultHttpService(),
       super(
         publishableKey: publishableKey,
         loading: loading,
         persistor: clerk.Persistor.none,
         fileCache: const NoopClerkFileCache(),
       );
}

class PrmApp extends StatelessWidget {
  static const String fallbackClerkPublishableKey = 'pk_test_dGVzdC5jbGVyay5hY2NvdW50cy5kZXYk';

  final clerk.HttpService? httpService;

  const PrmApp({super.key, this.httpService});

  @override
  Widget build(BuildContext context) {
    final String clerkKey = dotenv.get('CLERK_PUBLISHABLE_KEY', fallback: fallbackClerkPublishableKey);

    return ClerkAuth(
      config: AppClerkAuthConfig(
        publishableKey: clerkKey,
        httpService: httpService,
      ),
      child: MaterialApp.router(
        title: 'PRM Frontend',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
        ),
        builder: (BuildContext context, Widget? child) {
          return ClerkErrorListener(
            child: child ?? const SizedBox.shrink(),
          );
        },
        routerConfig: AppRouter.router,
      ),
    );
  }
}
