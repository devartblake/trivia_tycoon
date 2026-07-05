import 'package:flutter/material.dart';

/// Reusable answer option button with multiple states (normal, selected,
/// correct, incorrect, disabled).
///
/// Styled as a Trivia-Crack style pill: full-width white rounded card with a
/// soft drop shadow, centered text, and a press-down scale animation.
class AnswerOptionCard extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSelected;
  final bool isCorrect;
  final bool showFeedback;
  final bool isMultiplayer;

  const AnswerOptionCard({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSelected = false,
    this.isCorrect = false,
    this.showFeedback = false,
    this.isMultiplayer = false,
  });

  @override
  State<AnswerOptionCard> createState() => _AnswerOptionCardState();
}

class _AnswerOptionCardState extends State<AnswerOptionCard> {
  static const _inkColor = Color(0xFF39404A);

  bool _pressed = false;

  bool get _tappable => !widget.showFeedback && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white;
    Color textColor = _inkColor;
    Border? border;

    if (widget.showFeedback && widget.isSelected) {
      backgroundColor =
          widget.isCorrect ? Colors.green.shade600 : Colors.red.shade500;
      textColor = Colors.white;
    } else if (widget.showFeedback && widget.isCorrect) {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
      border = Border.all(color: Colors.green.shade400, width: 1.5);
    } else if (widget.isSelected && widget.isMultiplayer) {
      backgroundColor = const Color(0xFFEDEEFC);
      textColor = const Color(0xFF6366F1);
      border = Border.all(color: const Color(0xFF6366F1), width: 1.5);
    } else if (widget.isSelected) {
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade800;
      border = Border.all(color: Colors.blue.shade300, width: 1.5);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        button: true,
        enabled: _tappable,
        child: GestureDetector(
          onTapDown: _tappable ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _tappable ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              _tappable ? () => setState(() => _pressed = false) : null,
          onTap: _tappable ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 90),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 56),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: border,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: _pressed ? 0.10 : 0.22),
                    blurRadius: _pressed ? 3 : 6,
                    offset: Offset(0, _pressed ? 1 : 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
