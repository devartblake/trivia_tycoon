import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

/// Handles avatar image upload via the MinIO presigned-URL flow.
///
/// Flow:
///   1. `POST /users/me/avatar/upload-url` → get presigned PUT URL + permanent avatarUrl
///   2. HTTP PUT to the presigned URL with the image bytes (no auth — MinIO signs it)
///   3. Return the permanent [avatarUrl] for persistence in the player profile
class AvatarUploadService {
  final ApiService _api;
  final http.Client _httpClient;

  AvatarUploadService(this._api, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> _requestUploadUrl({
    required String contentType,
    required String fileName,
    required int contentLength,
  }) {
    return _api.post('/users/me/avatar/upload-url', body: {
      'contentType': contentType,
      'fileName': fileName,
      'contentLength': contentLength,
    });
  }

  /// Upload [file] to the player's avatar slot and return the permanent URL.
  ///
  /// Progress is reported via [onProgress] as a value from 0.0 to 1.0.
  /// The returned URL should be stored in the player profile as `avatarUrl`.
  Future<String> uploadAvatar({
    required XFile file,
    String contentType = 'image/jpeg',
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final fileName = file.name.isNotEmpty
        ? file.name
        : 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ticket = await _requestUploadUrl(
      contentType: contentType,
      fileName: fileName,
      contentLength: bytes.length,
    );

    final uploadUrl = ticket['uploadUrl'] as String? ?? '';
    // Accept 'publicUrl' (preferred) or 'avatarUrl' (legacy fallback).
    final permanentUrl = (ticket['publicUrl'] as String? ?? '').isNotEmpty
        ? ticket['publicUrl'] as String
        : ticket['avatarUrl'] as String? ?? '';

    if (uploadUrl.isEmpty) {
      throw Exception('Avatar upload: no upload URL returned by backend');
    }

    onProgress?.call(0.1);

    final putResponse = await _httpClient.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    onProgress?.call(1.0);

    if (putResponse.statusCode != 200 && putResponse.statusCode != 204) {
      throw Exception('Avatar upload failed: HTTP ${putResponse.statusCode}');
    }

    return permanentUrl;
  }
}
