import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/avatar_upload_service.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';
import 'package:trivia_tycoon/game/controllers/profile_avatar_controller.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// In-memory key-value storage — no Hive required.
class _FakeStorage extends GeneralKeyValueStorageService {
  final Map<String, String> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }
}

/// No-op cache — overrides the only method the controller calls.
class _FakeCache extends AppCacheService {
  @override
  Future<void> remove(String key) async {}
}

/// XFile backed by in-memory bytes (no real filesystem needed).
class _ByteXFile extends XFile {
  final Uint8List _bytes;
  _ByteXFile(this._bytes, {String name = 'avatar.jpg'})
      : super('fake/$name', name: name);

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

final _sampleFile = _ByteXFile(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]));

const _presignedUrl = 'https://minio.example.test/avatar.jpg?sig=abc';
const _permanentUrl = 'https://cdn.example.test/avatars/user-1/avatar.jpg';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ApiService _fakeApiService(Map<String, dynamic> ticketResponse) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: ticketResponse,
      ));
    },
  ));
  return ApiService(
      baseUrl: 'https://example.test', dio: dio, initializeCache: false);
}

AvatarUploadService _uploadService({int putStatus = 200}) {
  return AvatarUploadService(
    _fakeApiService({'uploadUrl': _presignedUrl, 'publicUrl': _permanentUrl}),
    httpClient: MockClient((_) async => http.Response('', putStatus)),
  );
}

ProfileAvatarController _controller({AvatarUploadService? upload}) {
  return ProfileAvatarController(
    keyValueStorage: _FakeStorage(),
    appCache: _FakeCache(),
    uploadService: upload,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  test('upload is skipped (no state change) when uploadService is null',
      () async {
    final controller = _controller();
    controller.imageFileForTesting = _sampleFile;

    await controller.retryUpload();

    expect(controller.isUploading, isFalse);
    expect(controller.remoteAvatarUrl, isNull);
    expect(controller.uploadError, isNull);
  });

  test('isUploading transitions false → true → false during successful upload',
      () async {
    final controller = _controller(upload: _uploadService());
    controller.imageFileForTesting = _sampleFile;

    final states = <bool>[];
    controller.addListener(() => states.add(controller.isUploading));

    await controller.retryUpload();

    expect(states, containsAllInOrder([true, false]));
    expect(controller.isUploading, isFalse);
  });

  test('remoteAvatarUrl is set after successful upload', () async {
    final controller = _controller(upload: _uploadService());
    controller.imageFileForTesting = _sampleFile;

    await controller.retryUpload();

    expect(controller.remoteAvatarUrl, _permanentUrl);
    expect(controller.uploadError, isNull);
  });

  test('uploadError is set when PUT returns 500', () async {
    final controller = _controller(upload: _uploadService(putStatus: 500));
    controller.imageFileForTesting = _sampleFile;

    await controller.retryUpload();

    expect(controller.uploadError, isNotNull);
    expect(controller.uploadError, contains('500'));
    expect(controller.isUploading, isFalse);
    expect(controller.remoteAvatarUrl, isNull);
  });

  test('retryUpload clears uploadError before re-attempting', () async {
    final controller = _controller(upload: _uploadService(putStatus: 503));
    controller.imageFileForTesting = _sampleFile;

    // First attempt fails.
    await controller.retryUpload();
    expect(controller.uploadError, isNotNull);

    // Rebuild controller with a succeeding upload service.
    final successController = _controller(upload: _uploadService(putStatus: 200));
    successController.imageFileForTesting = _sampleFile;

    // Second attempt succeeds — error is cleared.
    await successController.retryUpload();

    expect(successController.uploadError, isNull);
    expect(successController.remoteAvatarUrl, _permanentUrl);
  });
}
