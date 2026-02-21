import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_http_client.dart';

/// Wrapper around AuthHttpClient for backward compatibility
/// and additional convenience methods.
///
/// This provides a simple interface for making authenticated HTTP requests
/// with automatic token refresh and proper error handling.
class HttpClient {
  final AuthHttpClient _authClient;
  final String baseUrl;

  HttpClient({
    required AuthHttpClient authClient,
    required this.baseUrl,
  }) : _authClient = authClient;

  /// Build a URI from path and optional query parameters
  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  // ========================================
  // GET Requests
  // ========================================

  /// GET request returning JSON
  Future<Map<String, dynamic>> getJson(
      String path, {
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.get(_uri(path, query), headers: headers);
    _checkResponse(response, 'GET', path);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET request returning JSON list
  Future<List<dynamic>> getJsonList(
      String path, {
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.get(_uri(path, query), headers: headers);
    _checkResponse(response, 'GET', path);
    return jsonDecode(response.body) as List<dynamic>;
  }

  /// GET request returning raw response
  Future<http.Response> get(
      String path, {
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.get(_uri(path, query), headers: headers);
    _checkResponse(response, 'GET', path);
    return response;
  }

  // ========================================
  // POST Requests
  // ========================================

  /// POST request with JSON body, returning JSON
  Future<Map<String, dynamic>> postJson(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.post(
      _uri(path, query),
      headers: _jsonHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response, 'POST', path);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST request with JSON body, returning JSON list
  Future<List<dynamic>> postJsonList(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.post(
      _uri(path, query),
      headers: _jsonHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response, 'POST', path);
    return jsonDecode(response.body) as List<dynamic>;
  }

  /// POST request with JSON body, returning raw response
  Future<http.Response> post(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.post(
      _uri(path, query),
      headers: _jsonHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response, 'POST', path);
    return response;
  }

  // ========================================
  // PUT Requests
  // ========================================

  /// PUT request with JSON body, returning JSON
  Future<Map<String, dynamic>> putJson(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.put(
      _uri(path, query),
      headers: _jsonHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response, 'PUT', path);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PUT request with JSON body, returning raw response
  Future<http.Response> put(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.put(
      _uri(path, query),
      headers: _jsonHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response, 'PUT', path);
    return response;
  }

  // ========================================
  // PATCH Requests
  // ========================================

  /// PATCH request with JSON body, returning JSON
  Future<Map<String, dynamic>> patchJson(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.patch(
      _uri(path, query),
      headers: _jsonHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response, 'PATCH', path);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PATCH request with JSON body, returning raw response
  Future<http.Response> patch(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.patch(
      _uri(path, query),
      headers: _jsonHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response, 'PATCH', path);
    return response;
  }

  // ========================================
  // DELETE Requests
  // ========================================

  /// DELETE request returning JSON
  Future<Map<String, dynamic>> deleteJson(
      String path, {
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.delete(
      _uri(path, query),
      headers: headers,
    );
    _checkResponse(response, 'DELETE', path);

    // DELETE might return empty body
    if (response.body.isEmpty) {
      return {};
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// DELETE request returning raw response
  Future<http.Response> delete(
      String path, {
        Map<String, String>? query,
        Map<String, String>? headers,
      }) async {
    final response = await _authClient.delete(
      _uri(path, query),
      headers: headers,
    );
    _checkResponse(response, 'DELETE', path);
    return response;
  }

  // ========================================
  // Helper Methods
  // ========================================

  /// Merge custom headers with JSON content-type
  Map<String, String> _jsonHeaders(Map<String, String>? custom) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (custom != null) ...custom,
    };
  }

  /// Check response status and throw on error
  void _checkResponse(http.Response response, String method, String path) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return; // Success
    }

    // Try to extract error message from response body
    String errorMessage;
    try {
      final json = jsonDecode(response.body);
      if (json is Map && json.containsKey('message')) {
        errorMessage = json['message'].toString();
      } else if (json is Map && json.containsKey('error')) {
        errorMessage = json['error'].toString();
      } else {
        errorMessage = response.body;
      }
    } catch (e) {
      errorMessage = response.body.isEmpty ? 'Request failed' : response.body;
    }

    throw HttpException(
      method: method,
      path: path,
      statusCode: response.statusCode,
      message: errorMessage,
    );
  }

  /// Close the underlying HTTP client
  void close() {
    _authClient.close();
  }
}

/// Custom exception for HTTP errors with detailed information
class HttpException implements Exception {
  final String method;
  final String path;
  final int statusCode;
  final String message;

  HttpException({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() {
    return 'HttpException: $method $path failed with status $statusCode: $message';
  }
}