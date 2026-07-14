import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/manager/log_manager.dart';

/// Client for the **Synaptix.Compliance.Api** service (age verification, consent,
/// parental consent, privacy/data-subject requests).
///
/// This is a *separate* concern from [ComplianceApiClient], which targets the
/// external AML/KYC/geo service (`/api/kyc`, `/api/transaction/*`). These
/// endpoints are COPPA/GDPR consent endpoints and identify the caller from the
/// bearer token (no userId in the path).
///
/// The base URL points at the compliance service (or the gateway route that
/// fronts it); wire it from config the same way [ComplianceApiClient] is wired
/// from `COMPLIANCE_SERVICE_URL`.
class ComplianceConsentApiException implements Exception {
  final String message;
  final String path;
  final int? statusCode;

  const ComplianceConsentApiException({
    required this.message,
    required this.path,
    this.statusCode,
  });

  @override
  String toString() =>
      'ComplianceConsentApiException($path status=$statusCode): $message';
}

class AgeVerificationStatus {
  final int declaredAge;
  final bool isMinor;
  final DateTime? verifiedAt;

  const AgeVerificationStatus({
    required this.declaredAge,
    required this.isMinor,
    this.verifiedAt,
  });

  factory AgeVerificationStatus.fromJson(Map<String, dynamic> j) =>
      AgeVerificationStatus(
        declaredAge: j['declaredAge'] as int? ?? 0,
        isMinor: j['isMinor'] as bool? ?? false,
        verifiedAt: DateTime.tryParse(j['verifiedAt'] as String? ?? ''),
      );
}

class ParentalConsentInitiation {
  final String id;
  final String status;
  final DateTime? expiresAt;

  /// Raw token the backend emails to the parent (returned to the initiator).
  final String consentToken;

  const ParentalConsentInitiation({
    required this.id,
    required this.status,
    required this.consentToken,
    this.expiresAt,
  });

  factory ParentalConsentInitiation.fromJson(Map<String, dynamic> j) =>
      ParentalConsentInitiation(
        id: j['id'] as String? ?? '',
        status: j['status'] as String? ?? '',
        consentToken: j['consentToken'] as String? ?? '',
        expiresAt: DateTime.tryParse(j['expiresAt'] as String? ?? ''),
      );
}

class ComplianceConsentApiClient {
  final http.Client _http;
  final String _baseUrl;
  final String? Function()? accessTokenProvider;

  ComplianceConsentApiClient(
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
      LogManager.debug('[ComplianceConsentApiClient] $method $path -> $status');
    }
  }

  Never _fail(String method, String path, int status, String body) {
    throw ComplianceConsentApiException(
      message: body.isEmpty ? '$method failed' : body,
      path: path,
      statusCode: status,
    );
  }

  // ── Age verification ────────────────────────────────────────────────────

  /// POST /compliance/age-verification — submit the player's declared age.
  Future<bool> submitAge(int declaredAge) async {
    const path = '/compliance/age-verification';
    final res = await _http.post(_u(path),
        headers: _headers, body: jsonEncode({'declaredAge': declaredAge}));
    _log('POST', path, res.statusCode);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['isMinor']
              as bool? ??
          false;
    }
    _fail('POST', path, res.statusCode, res.body);
  }

  /// GET /compliance/age-verification/me — latest record, or null if none.
  Future<AgeVerificationStatus?> getAgeStatus() async {
    const path = '/compliance/age-verification/me';
    final res = await _http.get(_u(path), headers: _headers);
    _log('GET', path, res.statusCode);
    if (res.statusCode == 404) return null;
    if (res.statusCode == 200) {
      return AgeVerificationStatus.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    _fail('GET', path, res.statusCode, res.body);
  }

  // ── Consent ─────────────────────────────────────────────────────────────

  /// POST /compliance/consent — record a consent decision.
  Future<void> recordConsent({
    required String consentType,
    required bool consentGiven,
    required String policyVersion,
  }) async {
    const path = '/compliance/consent';
    final res = await _http.post(_u(path),
        headers: _headers,
        body: jsonEncode({
          'consentType': consentType,
          'consentGiven': consentGiven,
          'policyVersion': policyVersion,
        }));
    _log('POST', path, res.statusCode);
    if (res.statusCode != 200) _fail('POST', path, res.statusCode, res.body);
  }

  /// GET /compliance/consent/me — current consent records.
  Future<List<Map<String, dynamic>>> getConsents() async {
    const path = '/compliance/consent/me';
    final res = await _http.get(_u(path), headers: _headers);
    _log('GET', path, res.statusCode);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    _fail('GET', path, res.statusCode, res.body);
  }

  // ── Parental consent (minors) ─────────────────────────────────────────────

  /// POST /compliance/parental-consent/initiate — start the parent-consent flow.
  Future<ParentalConsentInitiation> initiateParentalConsent(
      String parentEmail) async {
    const path = '/compliance/parental-consent/initiate';
    final res = await _http.post(_u(path),
        headers: _headers, body: jsonEncode({'parentEmail': parentEmail}));
    _log('POST', path, res.statusCode);
    if (res.statusCode == 200) {
      return ParentalConsentInitiation.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    _fail('POST', path, res.statusCode, res.body);
  }

  /// GET /compliance/parental-consent/me — effective consent status string.
  Future<String> getParentalConsentStatus() async {
    const path = '/compliance/parental-consent/me';
    final res = await _http.get(_u(path), headers: _headers);
    _log('GET', path, res.statusCode);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['status']
              as String? ??
          'Unknown';
    }
    _fail('GET', path, res.statusCode, res.body);
  }

  /// DELETE /compliance/parental-consent/me — revoke consent.
  Future<void> revokeParentalConsent() async {
    const path = '/compliance/parental-consent/me';
    final res = await _http.delete(_u(path), headers: _headers);
    _log('DELETE', path, res.statusCode);
    if (res.statusCode != 204 && res.statusCode != 200) {
      _fail('DELETE', path, res.statusCode, res.body);
    }
  }

  // ── Privacy / data-subject requests ───────────────────────────────────────

  /// POST /compliance/privacy-requests — submit a request.
  /// [requestType] is e.g. `Export` or `Delete` (server validates the enum).
  /// Returns the created request id.
  Future<String> submitPrivacyRequest(String requestType) async {
    const path = '/compliance/privacy-requests';
    final res = await _http.post(_u(path),
        headers: _headers, body: jsonEncode({'requestType': requestType}));
    _log('POST', path, res.statusCode);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as String? ??
          '';
    }
    _fail('POST', path, res.statusCode, res.body);
  }

  /// GET /compliance/privacy-requests/{requestId} — status of a request.
  Future<Map<String, dynamic>> getPrivacyRequestStatus(String requestId) async {
    final path = '/compliance/privacy-requests/$requestId';
    final res = await _http.get(_u(path), headers: _headers);
    _log('GET', path, res.statusCode);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    _fail('GET', path, res.statusCode, res.body);
  }
}
