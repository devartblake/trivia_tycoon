import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/networking/encrypted_refresh_transport.dart';
import 'package:synaptix/core/services/auth_api_client.dart';
import 'package:synaptix/core/services/device_id_service.dart';
import 'package:synaptix/core/services/storage/secure_storage.dart';

class _FakeDeviceIdService extends DeviceIdService {
  _FakeDeviceIdService() : super(SecureStorage());
}

/// Records the encrypted refresh call and returns a canned rotated-token map.
class _FakeRefreshTransport implements EncryptedRefreshTransport {
  _FakeRefreshTransport(this.response);
  final Map<String, dynamic> response;
  int calls = 0;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> postEncrypted(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    calls++;
    lastPath = path;
    lastBody = body;
    return response;
  }
}

void main() {
  test('refresh() routes through the encrypted transport and parses the session',
      () async {
    final transport = _FakeRefreshTransport({
      'accessToken': 'new-access',
      'refreshToken': 'new-refresh',
      'expiresIn': 900,
      // nested user.id shape (device/bootstrap + login) — must be parsed.
      'user': {'id': '712dbcd9-6cea-45c7-81ed-e902d1c309e7', 'handle': 'guest'},
    });

    final api = AuthApiClient(
      http.Client(),
      apiBaseUrl: 'https://api.test',
      deviceId: _FakeDeviceIdService(),
    );
    api.attachRefreshTransport(transport);

    final session = await api.refresh(
      refreshToken: 'old-refresh',
      deviceId: 'ios-sim',
      deviceType: 'ios',
    );

    // Went over the encrypted channel (not the plain http.Client)...
    expect(transport.calls, 1);
    expect(transport.lastPath, AuthApiClient.refreshPath);
    expect(transport.lastBody!['refreshToken'], 'old-refresh');
    // ...and the rotated tokens + nested user id were parsed.
    expect(session.accessToken, 'new-access');
    expect(session.refreshToken, 'new-refresh');
    expect(session.userId, '712dbcd9-6cea-45c7-81ed-e902d1c309e7');
  });
}
