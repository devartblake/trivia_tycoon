import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_manager.dart';

class AuthedHttpClient {
  final String apiBaseUrl;
  final AuthManager auth;
  final http.Client _http;

  AuthedHttpClient({
    required this.apiBaseUrl,
    required this.auth,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  Uri _uri(String path) => Uri.parse('$apiBaseUrl$path');

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    return _sendWithRefresh(() => _http.get(_uri(path), headers: headers));
  }

  Future<http.Response> post(String path, {Map<String, String>? headers, Object? body}) async {
    return _sendWithRefresh(() => _http.post(_uri(path), headers: headers, body: body));
  }

  Future<http.Response> _sendWithRefresh(Future<http.Response> Function() send) async {
    // attempt #1
    final resp1 = await send();
    if (resp1.statusCode != 401) return resp1;

    // refresh & retry
    await auth.refreshNow();
    final resp2 = await send();
    return resp2;
  }

  /// Helper for JSON POST with auth header attached.
  Future<http.Response> postJson(String path, Map<String, dynamic> jsonBody) async {
    final token = await auth.getValidAccessToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return post(path, headers: headers, body: jsonEncode(jsonBody));
  }

  Future<http.Response> getJson(String path) async {
    final token = await auth.getValidAccessToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return get(path, headers: headers);
  }
}
