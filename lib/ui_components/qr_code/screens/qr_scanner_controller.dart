import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../core/zxing/common/binary_bitmap.dart';
import '../core/zxing/common/bit_matrix.dart';
import '../core/zxing/decoder/qr_decoder.dart';

class QrScannerController {
  final Function(String result)? onScan;

  CameraController? _cameraController;
  bool _isProcessing = false;

  QrScannerController({this.onScan});

  /// Safe access (may be null before initialize completes).
  CameraController? get cameraOrNull => _cameraController;

  bool get hasCamera => _cameraController != null;

  bool get isInitialized => _cameraController?.value.isInitialized ?? false;

  bool get isTorchOn => _cameraController?.value.flashMode == FlashMode.torch;

  bool get isPaused {
    final c = _cameraController;
    if (c == null || !c.value.isInitialized) return true;
    return !c.value.isStreamingImages;
  }

  Future<void> initialize() async {
    // Avoid double-init if initialize gets called more than once.
    if (_cameraController != null) {
      if (_cameraController!.value.isInitialized) return;
    }

    final cameras = await availableCameras();
    final rearCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      rearCamera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    _cameraController = controller;

    await controller.initialize();
    await controller.startImageStream(_processCameraImage);
  }

  Future<void> toggleTorch() async {
    final c = _cameraController;
    if (c == null || !c.value.isInitialized) return;

    final newMode = isTorchOn ? FlashMode.off : FlashMode.torch;
    await c.setFlashMode(newMode);
  }

  Future<void> pauseCamera() async {
    final c = _cameraController;
    if (c == null || !c.value.isInitialized) return;
    if (!c.value.isStreamingImages) return;

    await c.stopImageStream();
  }

  Future<void> resumeCamera() async {
    final c = _cameraController;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isStreamingImages) return;

    await c.startImageStream(_processCameraImage);
  }

  void dispose() {
    final c = _cameraController;
    _cameraController = null;
    c?.dispose();
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final luminance = _convertToLuminance(image);
      final matrix = _toBitMatrix(luminance, image.width, image.height);
      final binaryBitmap = BinaryBitmap(matrix);

      final result = await QrDecoder().decode(binaryBitmap);

      if (result != null) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
        onScan?.call(result.text);
      }
    } catch (_) {
      // silent fail (intended)
    } finally {
      _isProcessing = false;
    }
  }

  Uint8List _convertToLuminance(CameraImage image) {
    // Using Y plane from YUV420 format
    return image.planes[0].bytes;
  }

  BitMatrix _toBitMatrix(Uint8List luminance, int width, int height) {
    final matrix = BitMatrix(width, height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = luminance[y * width + x];
        matrix.set(x, y, pixel < 128); // threshold
      }
    }
    return matrix;
  }
}
