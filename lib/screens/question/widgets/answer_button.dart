import 'package:flutter/material.dart';

class EnhancedAnswerButton extends StatefulWidget {
  final String answerText;
  final VoidCallback onPressed;
  final bool isSelected;
  final bool isCorrect;
  final bool showFeedback;
  final String optionLabel; // A, B, C, D
  final bool isDisabled;

  const EnhancedAnswerButton({
    super.key,
    required this.answerText,
    required this.onPressed,
    required this.optionLabel,
    this.isSelected = false,
    this.isCorrect = false,
    this.showFeedback = false,
    this.isDisabled = false,
  });

  @override
  State<EnhancedAnswerButton> createState() => _EnhancedAnswerButtonState();
}

class _EnhancedAnswerButtonState extends State<EnhancedAnswerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getButtonColor() {
    if (widget.showFeedback) {
      if (widget.isSelected) {
        return widget.isCorrect ? Colors.green.shade600 : Colors.red.shade600;
      } else if (widget.isCorrect) {
        return Colors.green.shade600;
      }
    }

    if (widget.isSelected && !widget.showFeedback) {
      return Colors.blue.shade600;
    }

    return Colors.white;
  }

  Color _getTextColor() {
    if (widget.showFeedback || widget.isSelected) {
      return Colors.white;
    }
    return Colors.grey.shade800;
  }

  Color _getBorderColor() {
    if (widget.showFeedback) {
      if (widget.isSelected) {
        return widget.isCorrect ? Colors.green.shade600 : Colors.red.shade600;
      } else if (widget.isCorrect) {
        return Colors.green.shade600;
      }
    }

    if (widget.isSelected && !widget.showFeedback) {
      return Colors.blue.shade600;
    }

    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isSelected || widget.showFeedback
                  ? [
                BoxShadow(
                  color: _getButtonColor().withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isDisabled ? null : () {
                  _animationController.forward().then((_) {
                    _animationController.reverse();
                  });
                  widget.onPressed();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getButtonColor(),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getBorderColor(),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Option Label (A, B, C, D)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.showFeedback || widget.isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.optionLabel,
                            style: TextStyle(
                              color: widget.showFeedback || widget.isSelected
                                  ? Colors.white
                                  : Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Answer Text
                      Expanded(
                        child: Text(
                          widget.answerText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getTextColor(),
                            height: 1.3,
                          ),
                        ),
                      ),

                      // Feedback Icon
                      if (widget.showFeedback) ...[
                        const SizedBox(width: 8),
                        Icon(
                          widget.isCorrect ? Icons.check_circle : Icons.cancel,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
