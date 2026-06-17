import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/dto/web_link_dto.dart';
import '../../game/providers/web_link_providers.dart';

/// Widget shown on the **web** login screen that:
/// 1. Requests a QR token from the backend.
/// 2. Renders it as a QR code the user scans with the mobile app.
/// 3. Polls the backend every 3 s; navigates to [onSuccess] when consumed.
///
/// Usage (web-only):
/// ```dart
/// if (kIsWeb)
///   QrLinkWidget(onSuccess: (sessionToken) { /* store and navigate */ })
/// ```
class QrLinkWidget extends ConsumerStatefulWidget {
  final void Function(String sessionToken) onSuccess;

  const QrLinkWidget({super.key, required this.onSuccess});

  @override
  ConsumerState<QrLinkWidget> createState() => _QrLinkWidgetState();
}

class _QrLinkWidgetState extends ConsumerState<QrLinkWidget> {
  static const _pollInterval = Duration(seconds: 3);

  QrTokenResponse? _token;
  bool _isLoading = false;
  bool _isExpired = false;
  bool _isPolling = false;
  bool _isComplete = false;
  String? _errorMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchToken() async {
    _pollTimer?.cancel();
    setState(() {
      _isLoading = true;
      _isExpired = false;
      _isPolling = false;
      _isComplete = false;
      _errorMessage = null;
      _token = null;
    });

    try {
      final service = ref.read(webLinkServiceProvider);
      final token = await service.generateQrToken();
      if (!mounted) return;
      setState(() {
        _token = token;
        _isLoading = false;
      });
      _startPolling(token.qrToken, token.expiresIn);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not generate QR code. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _startPolling(String qrToken, int expiresIn) {
    if (expiresIn <= 0) {
      setState(() => _isExpired = true);
      return;
    }

    final startedAt = DateTime.now();
    final maxAge = Duration(seconds: expiresIn);

    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isPolling || _isComplete) return;

      if (DateTime.now().difference(startedAt) >= maxAge) {
        timer.cancel();
        if (mounted) setState(() => _isExpired = true);
        return;
      }

      _isPolling = true;
      try {
        final service = ref.read(webLinkServiceProvider);
        final status = await service.pollQrStatus(qrToken);

        if (!mounted) return;

        if (status.status == QrLinkStatus.consumed &&
            status.sessionToken != null) {
          _isComplete = true;
          timer.cancel();
          widget.onSuccess(status.sessionToken!);
          return;
        }

        if (status.status == QrLinkStatus.expired) {
          timer.cancel();
          setState(() => _isExpired = true);
        }
      } catch (_) {
        // Poll failures are non-fatal; the next tick will retry.
      } finally {
        _isPolling = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Scan with Mobile App',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const SizedBox(
              height: 200,
              width: 200,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
            )
          else if (_errorMessage != null || _isExpired)
            SizedBox(
              height: 200,
              width: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_rounded,
                      size: 48, color: Colors.white38),
                  const SizedBox(height: 12),
                  Text(
                    _isExpired ? 'QR code expired' : _errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (_token != null)
            QrImageView(
              data: _token!.qrToken,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
          const SizedBox(height: 16),
          Text(
            _isExpired
                ? 'QR code expired'
                : 'Open the Synaptix app → Settings → Link to Web',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _fetchToken,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh QR'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }
}
