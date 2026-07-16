import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/game/providers/riverpod_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/qr_scan_type.dart';
import 'qr_scanner_controller.dart';
import '../widgets/scan_box_overlay.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  late final QrScannerController _controller;
  late final Future<void> _initFuture;

  String? _scanResult;
  QrScanType? _scanType;

  @override
  void initState() {
    super.initState();

    _controller = QrScannerController(
      onScan: (result) async {
        if (_scanResult != null) return;

        final historyService = ref.read(qrHistoryServiceProvider);
        await historyService.saveScan(result);

        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);

        if (!mounted) return;
        setState(() {
          _scanResult = result;
          _scanType = detectQrType(result);
        });

        await _controller.pauseCamera();
      },
    );

    _initFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) setState(() {});
  }

  Future<void> _resumeScan() async {
    setState(() {
      _scanResult = null;
      _scanType = null;
    });
    await _controller.resumeCamera();
  }

  Future<void> _confirmResult() async {
    if (_scanType == QrScanType.url) {
      final uri = Uri.tryParse(_scanResult ?? '');
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        Navigator.of(context).pop(_scanResult);
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(_scanResult);
  }

  void _cancelScan() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: kIsWeb ? _buildWebUnsupported() : _buildScanner(),
    );
  }

  Widget _buildWebUnsupported() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            const Text(
              'QR scanning is available in the mobile app.',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Use a link code or open this scanner on iOS or Android.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _cancelScan,
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        final cam = _controller.cameraOrNull;

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Camera unavailable: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done ||
            cam == null ||
            !cam.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            AspectRatio(
              aspectRatio: cam.value.aspectRatio,
              child: CameraPreview(cam),
            ),
            ScanBoxOverlay(type: _scanType),
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  if (_scanResult != null) ...[
                    Text(
                      "Type: ${_scanType?.name.toUpperCase()}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Scanned: $_scanResult",
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          onPressed: _confirmResult,
                          label: const Text("Use"),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          onPressed: _resumeScan,
                          label: const Text("Rescan"),
                        ),
                        TextButton(
                          onPressed: _cancelScan,
                          child: const Text("Cancel"),
                        ),
                      ],
                    ),
                  ],
                  if (_scanResult == null)
                    IconButton(
                      icon: Icon(
                        _controller.isTorchOn
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: _toggleTorch,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
