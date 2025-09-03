import 'package:flutter/material.dart';
import 'qr_code_widget.dart';

class AnimatedQrPopup {
  static void show(BuildContext context, {required String data}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnimatedQrSheet(data: data),
    );
  }
}

class _AnimatedQrSheet extends StatefulWidget {
  final String data;
  const _AnimatedQrSheet({required this.data});

  @override
  State<_AnimatedQrSheet> createState() => _AnimatedQrSheetState();
}

class _AnimatedQrSheetState extends State<_AnimatedQrSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Share Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                QrCodeWidget(
                  data: widget.data,
                  size: 180,
                  dotColor: Colors.deepPurple,
                  backgroundColor: Colors.white,
                  roundedDots: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
