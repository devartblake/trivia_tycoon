import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:trivia_tycoon/ui_components/qr_code/services/qr_history_service.dart';
import 'package:trivia_tycoon/ui_components/qr_code/widgets/qr_scan_preview_modal.dart';
import '../core/zxing/common/binary_bitmap.dart';
import '../core/zxing/common/bit_matrix.dart';
import '../core/zxing/decoder/qr_decoder.dart';

class QrCameraScanner extends StatefulWidget {
  final void Function(String text)? onScan;
  final double scanBoxSize;
  final bool enableTorch;

  const QrCameraScanner({
    super.key,
    this.onScan,
    this.scanBoxSize = 240.0,
    this.enableTorch = true,
  });

  @override
  State<QrCameraScanner> createState() => _QrCameraScannerState();
}

class _QrCameraScannerState extends State<QrCameraScanner> {
  late CameraController _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _torchOn = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final rear = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    _controller = CameraController(rear, ResolutionPreset.low, enableAudio: false);
    await _controller.initialize();
    await _controller.startImageStream(_processCameraImage);
    setState(() => _isInitialized = true);
  }

  Future<void> pauseScan() async {
    _isPaused = true;
  }

  Future<void> resumeScan() async {
    _isPaused = false;
  }

  void _toggleTorch() async {
    _torchOn = !_torchOn;
    await _controller.setFlashMode(_torchOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  void _processCameraImage(CameraImage image) async {
    if (_isPaused || _isProcessing || image.format.group != ImageFormatGroup.yuv420) return;
    _isProcessing = true;

    try {
      final luminance = _convertToLuminance(image);
      final matrix = _toBitMatrix(luminance, image.width, image.height);
      final result = await QrDecoder().decode(BinaryBitmap(matrix));

      if (result != null) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);

        // Save to scan history
        await QrHistoryService.instance.saveScan(result.text);

        // Pause scanning while modal is shown
        await pauseScan();
        if (!mounted) return;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => QrScanPreviewModal(
            scanText: result.text,
            onAction: () {
              Navigator.of(context).pop();
              widget.onScan?.call(result.text);
              resumeScan(); // Resume after modal
            },
          ),
        );
      }
    } catch (_) {
      // silent fail
    } finally {
      _isProcessing = false;
    }
  }

  Uint8List _convertToLuminance(CameraImage image) {
    return image.planes[0].bytes;
  }

  BitMatrix _toBitMatrix(Uint8List luminance, int width, int height) {
    final matrix = BitMatrix(width, height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = luminance[y * width + x];
        matrix.set(x, y, pixel < 128); // simple threshold
      }
    }
    return matrix;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Center(child: CircularProgressIndicator());

    return Stack(
      alignment: Alignment.center,
      children: [
        CameraPreview(_controller),
        CustomPaint(
          size: Size(widget.scanBoxSize, widget.scanBoxSize),
          painter: _ScanBoxPainter(),
        ),
        if (widget.enableTorch)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: _toggleTorch,
              child: Icon(_torchOn ? Icons.flash_off : Icons.flash_on),
            ),
          ),
      ],
    );
  }
}

class _ScanBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
