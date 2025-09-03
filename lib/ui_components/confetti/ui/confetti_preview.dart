import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/confetti/models/confetti_settings.dart';
import '../core/confetti_widget.dart';
import '../core/confetti_controller.dart';
import '../core/confetti_theme.dart';

class ConfettiPreview extends StatefulWidget {
  final ConfettiTheme theme;
  final ConfettiSettings settings;
  final ConfettiController controller;

  const ConfettiPreview({
    super.key,
    required this.theme,
    required this.settings,
    required this.controller
  });

  @override
  _ConfettiPreviewState createState() => _ConfettiPreviewState();
}

class _ConfettiPreviewState extends State<ConfettiPreview> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController();
    _startPreview();
  }

  void _startPreview() {
    _controller.updateTheme(widget.theme);
    _controller.start();
  }

  @override
  void didUpdateWidget(covariant ConfettiPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      _startPreview();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            ConfettiWidget(
              controller: _controller,
              theme: widget.theme,
            ),
            Center(
              child: Text(
                "Preview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}