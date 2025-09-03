import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../core/zxing/common/binary_bitmap.dart';
import '../core/zxing/common/bit_matrix.dart';
import '../core/zxing/decoder/qr_decoder.dart';

class QrScannerController {
  final Function(String result)? onScan;
  late CameraController _cameraController;
  bool _isProcessing = false;
  bool get isTorchOn => _cameraController.value.flashMode == FlashMode.torch;

  QrScannerController({this.onScan});

  Future<void> toggleTorch() async {
    final newMode = isTorchOn ? FlashMode.off : FlashMode.torch;
    await _cameraController.setFlashMode(newMode);
  }

  bool get isPaused => !_cameraController.value.isStreamingImages;

  Future<void> pauseCamera() async {
    await _cameraController.stopImageStream();
  }

  Future<void> resumeCamera() async {
    await _cameraController.startImageStream(_processCameraImage);
  }

  Future<void> initialize() async {
    final cameras = await availableCameras();
    final rearCamera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.back);

    _cameraController = CameraController(
      rearCamera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    await _cameraController.initialize();
    _cameraController.startImageStream(_processCameraImage);
  }

  CameraController get camera => _cameraController;

  void dispose() {
    _cameraController.dispose();
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
        HapticFeedback.mediumImpact(); // 📳
         SystemSound.play(SystemSoundType.click); // 🔔
        onScan?.call(result.text);
      }
    } catch (e) {
      // silent fail
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
