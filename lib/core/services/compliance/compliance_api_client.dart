import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/manager/log_manager.dart';
import 'compliance_status_model.dart';

class ComplianceApiException implements Exception {
  final String message;
  final String path;
  final int? statusCode;

  const ComplianceApiException({
    required this.message,
    required this.path,
    this.statusCode,
  });

  @override
  String toString() =>
      'ComplianceApiException($path status=$statusCode): $message';
}

class ComplianceApiClient {
  final http.Client _http;
  final String _baseUrl;
  // Injected at runtime after login; returns null when not authenticated
  final String? Function()? accessTokenProvider;

  ComplianceApiClient(
    this._http, {
    required String baseUrl,
    this.accessTokenProvider,
  }) : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;

  Uri _u(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    final token = accessTokenProvider?.call();
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  void _log(String method, String path, int status) {
    if (kDebugMode) {
      LogManager.debug('[ComplianceApiClient] $method $path -> $status');
    }
  }

  // ── Compliance status ─────────────────────────────────────────────────────

  Future<ComplianceStatus> getStatus(String userId) async {
    final path = '/api/compliance/status/$userId';
    try {
      final res = await _http.get(_u(path), headers: _headers);
      _log('GET', path, res.statusCode);
      if (res.statusCode == 200) {
        return ComplianceStatus.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw ComplianceApiException(
          message: 'Failed to get compliance status',
          path: path,
          statusCode: res.statusCode);
    } catch (e) {
      if (e is ComplianceApiException) rethrow;
      throw ComplianceApiException(message: '$e', path: path);
    }
  }

  // ── KYC ───────────────────────────────────────────────────────────────────

  Future<KycInitiateResult> initiateKyc(String userId, String returnUrl) async {
    const path = '/api/kyc/initiate';
    try {
      final res = await _http.post(
        _u(path),
        headers: _headers,
        body: jsonEncode({'userId': userId, 'returnUrl': returnUrl}),
      );
      _log('POST', path, res.statusCode);
      if (res.statusCode == 200) {
        return KycInitiateResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
      throw ComplianceApiException(
        message: 'Failed to initiate KYC',
        path: path,
        statusCode: res.statusCode,
      );
    } catch (e) {
      if (e is ComplianceApiException) rethrow;
      throw ComplianceApiException(message: '$e', path: path);
    }
  }

  // ── Age verification ──────────────────────────────────────────────────────

  Future<AgeVerificationResult> verifyAge(
      String userId, DateTime dateOfBirth) async {
    const path = '/api/transaction/age-verify';
    try {
      final dob = '${dateOfBirth.year.toString().padLeft(4, '0')}-'
          '${dateOfBirth.month.toString().padLeft(2, '0')}-'
          '${dateOfBirth.day.toString().padLeft(2, '0')}';
      final res = await _http.post(
        _u(path),
        headers: _headers,
        body: jsonEncode({'userId': userId, 'dateOfBirth': dob}),
      );
      _log('POST', path, res.statusCode);
      if (res.statusCode == 200) {
        return AgeVerificationResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
      throw ComplianceApiException(
        message: 'Failed to verify age',
        path: path,
        statusCode: res.statusCode,
      );
    } catch (e) {
      if (e is ComplianceApiException) rethrow;
      throw ComplianceApiException(message: '$e', path: path);
    }
  }

  // ── Geo check ─────────────────────────────────────────────────────────────

  Future<GeoCheckResult> checkGeo(String userId, String stateCode) async {
    const path = '/api/transaction/geo-check';
    try {
      final res = await _http.post(
        _u(path),
        headers: _headers,
        body: jsonEncode({'userId': userId, 'stateCode': stateCode}),
      );
      _log('POST', path, res.statusCode);
      if (res.statusCode == 200) {
        return GeoCheckResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
      throw ComplianceApiException(
        message: 'Failed to check geo compliance',
        path: path,
        statusCode: res.statusCode,
      );
    } catch (e) {
      if (e is ComplianceApiException) rethrow;
      throw ComplianceApiException(message: '$e', path: path);
    }
  }

  // ── AML transaction check ─────────────────────────────────────────────────

  Future<AmlCheckResult> checkTransaction(
    String userId,
    double amount,
    String network,
    String transactionType,
  ) async {
    const path = '/api/transaction/check';
    try {
      final res = await _http.post(
        _u(path),
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
          'network': network,
          'transactionType': transactionType,
        }),
      );
      _log('POST', path, res.statusCode);
      if (res.statusCode == 200) {
        return AmlCheckResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
      throw ComplianceApiException(
        message: 'Failed to run AML check',
        path: path,
        statusCode: res.statusCode,
      );
    } catch (e) {
      if (e is ComplianceApiException) rethrow;
      throw ComplianceApiException(message: '$e', path: path);
    }
  }

  // ── CCPA data requests ────────────────────────────────────────────────────

  Future<DataSubjectRequestResult> requestDataExport(String userId) async {
    final path = '/api/privacy/export/$userId';
    try {
      final res = await _http.post(_u(path), headers: _headers);
      _log('POST', path, res.statusCode);
      if (res.statusCode == 200) {
        return DataSubjectRequestResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
      throw ComplianceApiException(
        message: 'Failed to request data export',
        path: path,
        statusCode: res.statusCode,
      );
    } catch (e) {
      if (e is ComplianceApiException) rethrow;
      throw ComplianceApiException(message: '$e', path: path);
    }
  }

  Future<DataSubjectRequestResult> requestDataDeletion(String userId) async {
    final path = '/api/privacy/$userId';
    try {
      final res = await _http.delete(_u(path), headers: _headers);
      _log('DELETE', path, res.statusCode);
      if (res.statusCode == 200) {
        return DataSubjectRequestResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
      throw ComplianceApiException(
        message: 'Failed to request data deletion',
        path: path,
        statusCode: res.statusCode,
      );
    } catch (e) {
      if (e is ComplianceApiException) rethrow;
      throw ComplianceApiException(message: '$e', path: path);
    }
  }

  // ── Consent ───────────────────────────────────────────────────────────────

  Future<void> recordConsent(
    String userId,
    String consentType, {
    required bool granted,
  }) async {
    const path = '/api/privacy/consent';
    try {
      final res = await _http.post(
        _u(path),
        headers: _headers,
        body: jsonEncode(
          {'userId': userId, 'consentType': consentType, 'granted': granted},
        ),
      );
      _log('POST', path, res.statusCode);
      if (res.statusCode != 200) {
        throw ComplianceApiException(
          message: 'Failed to record consent',
          path: path,
          statusCode: res.statusCode,
        );
      }
    } catch (e) {
      if (e is ComplianceApiException) rethrow;
      throw ComplianceApiException(message: '$e', path: path);
    }
  }
}
