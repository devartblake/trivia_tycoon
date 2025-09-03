import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/ui_components/qr_code/models/qr_scan_type.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'qr_scanner_controller.dart';
import '../widgets/scan_box_overlay.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  late QrScannerController _controller;
  String? _scanResult;
  QrScanType? _scanType;

  @override
  void initState() {
    super.initState();
    _controller = QrScannerController(
      onScan: (result) async {
        if (_scanResult == null) {
          final historyService = ref.read(qrHistoryServiceProvider);
          await historyService.saveScan(result);
          HapticFeedback.mediumImpact();
          SystemSound.play(SystemSoundType.click);

          setState(() {
            _scanResult = result;
            _scanType = detectQrType(result);
          });

          await _controller.pauseCamera();
        }
      },
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() {});
  }

  void _resumeScan() async {
    setState(() {
      _scanResult = null;
      _scanType = null;
    });
    await _controller.resumeCamera();
  }

  void _confirmResult() async {
    if (_scanType == QrScanType.url) {
      final uri = Uri.tryParse(_scanResult ?? '');
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        Navigator.of(context).pop(_scanResult);
        return;
      }
    }

    if(!mounted) return;
    Navigator.of(context).pop(_scanResult);
  }

  void _cancelScan() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final cameraInitialized = _controller.camera.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          if (cameraInitialized)
            AspectRatio(
              aspectRatio: _controller.camera.value.aspectRatio,
              child: CameraPreview(_controller.camera),
            )
          else
            const Center(child: CircularProgressIndicator()),

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
                      _controller.isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleTorch,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
