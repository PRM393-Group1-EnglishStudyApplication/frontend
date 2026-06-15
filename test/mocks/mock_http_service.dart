import 'dart:async';
import 'dart:io';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/utils/clerk_file_cache.dart';
import 'package:http/http.dart' as http;

class MockHttpService implements clerk.HttpService {
  final String? clientResponse;

  const MockHttpService({this.clientResponse});

  @override
  Future<void> initialize() async {}

  @override
  void terminate() {}

  @override
  Future<bool> ping(Uri uri, {required Duration timeout}) async => true;

  @override
  Future<http.Response> send(
    clerk.HttpMethod method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    String? body,
  }) async {
    print('MockHttpService request: $method $uri');
    final path = uri.path;
    if (path.endsWith('/client')) {
      return http.Response(
        clientResponse ?? '{"response":{"id":"test_client","sessions":[]}}',
        200,
      );
    } else if (path.endsWith('/environment')) {
      return http.Response('{"maintenance_mode":false}', 200);
    }
    return http.Response('{}', 200);
  }

  @override
  Future<http.Response> sendByteStream(
    clerk.HttpMethod method,
    Uri uri,
    http.ByteStream byteStream,
    int length,
    Map<String, String> headers,
  ) async {
    return http.Response('{}', 200);
  }
}

class MockClerkFileCache implements ClerkFileCache {
  const MockClerkFileCache();

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
    return const Stream.empty();
  }
}

class TestClerkAuthConfig extends ClerkAuthConfig {
  @override
  final clerk.HttpService httpService;

  TestClerkAuthConfig({
    required super.publishableKey,
    required this.httpService,
  }) : super(
          persistor: clerk.Persistor.none,
          fileCache: const MockClerkFileCache(),
        );
}

const String janeDoeClientResponse = r'''
{
  "response": {
    "id": "client_123",
    "status": "active",
    "last_active_session_id": "sess_123",
    "sessions": [
      {
        "id": "sess_123",
        "status": "active",
        "last_active_at": 1600000000000,
        "expire_at": 1700000000000,
        "abandon_at": 1700000000000,
        "public_user_data": {
          "user_id": "user_123",
          "first_name": "Jane",
          "last_name": "Doe",
          "profile_image_url": "",
          "image_url": "",
          "has_image": false,
          "identifier": "jane.doe@example.com"
        },
        "user": {
          "id": "user_123",
          "username": "janedoe",
          "first_name": "Jane",
          "last_name": "Doe",
          "profile_image_url": "",
          "image_url": "",
          "has_image": false,
          "primary_email_address_id": "email_123",
          "primary_phone_number_id": null,
          "primary_web3_wallet_id": null,
          "public_metadata": {},
          "private_metadata": {},
          "unsafe_metadata": {},
          "email_addresses": [
            {
              "id": "email_123",
              "email_address": "jane.doe@example.com",
              "reserved": false,
              "verification": {
                "status": "verified",
                "strategy": "email_code",
                "attempts": 1,
                "expire_at": 1700000000000
              },
              "created_at": 1600000000000,
              "updated_at": 1600000000000
            }
          ],
          "phone_numbers": [],
          "web3_wallets": [],
          "passkeys": [],
          "organization_memberships": [],
          "create_organization_enabled": false,
          "password_enabled": true,
          "two_factor_enabled": false,
          "totp_enabled": false,
          "backup_code_enabled": false,
          "last_sign_in_at": 1600000000000,
          "banned": false,
          "locked": false,
          "lockout_expires_in_seconds": null,
          "verification_attempts_remaining": 5,
          "created_at": 1600000000000,
          "updated_at": 1600000000000,
          "last_active_at": 1600000000000,
          "delete_self_enabled": false
        }
      }
    ]
  }
}
''';
