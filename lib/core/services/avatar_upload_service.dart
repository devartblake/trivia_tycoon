import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Handles avatar image upload via the MinIO presigned-URL flow.
///
/// Flow:
///   1. `POST /users/me/avatar/upload-url` → get presigned PUT URL + avatarUrl
///   2. HTTP PUT to the presigned URL with the image bytes
///   3. Return the permanent [avatarUrl] for persistence in the player profile
class AvatarUploadService {
  final ApiService _api;

  const AvatarUploadService(this._api);

  /// Request a presigned upload URL from the backend.
  ///
  /// [contentType] should be the image MIME type, e.g. `image/jpeg` or `image/png`.
  /// Returns `{'uploadUrl': '...', 'avatarUrl': '...'}`.
  Future<Map<String, dynamic>> _requestUploadUrl(String contentType) {
    return _api.post('/users/me/avatar/upload-url', body: {
      'contentType': contentType,
    });
  }

  /// Upload [file] to the player's avatar slot.
  ///
  /// Returns the permanent [avatarUrl] to store in the player profile.
  /// Progress is reported via [onProgress] as a value from 0.0 to 1.0.
  Future<String> uploadAvatar({
    required File file,
    String contentType = 'image/jpeg',
    void Function(double progress)? onProgress,
  }) async {
    final response = await _requestUploadUrl(contentType);
    final uploadUrl = response['uploadUrl'] as String?;
    final avatarUrl = response['avatarUrl'] as String?;

    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('Avatar upload: no upload URL returned by backend');
    }

    final bytes = await file.readAsBytes();
    onProgress?.call(0.1);

    final putResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    onProgress?.call(1.0);

    if (putResponse.statusCode != 200 && putResponse.statusCode != 204) {
      throw Exception(
          'Avatar upload failed: HTTP ${putResponse.statusCode}');
    }

    return avatarUrl ?? '';
  }
}
