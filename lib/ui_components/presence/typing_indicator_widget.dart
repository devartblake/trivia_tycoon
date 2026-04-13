import 'package:flutter/material.dart';
import '../../core/animations/animation_manager.dart';
import '../../core/services/presence/typing_indicator_service.dart';
import '../../screens/messages/widgets/safe_text.dart';

/// Animated widget that shows typing indicators in chat
class TypingIndicatorWidget extends StatefulWidget {
  final String conversationId;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Duration animationDuration;

  const TypingIndicatorWidget({
    super.key,
    required this.conversationId,
    this.padding,
    this.textStyle,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _dotsController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  TypingIndicatorService? _typingService;
  bool _isVisible = false;
  String _currentText = '';

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = AnimationManager.fadeIn(animation: _fadeController);

    _slideAnimation = Tween<double>(
      begin: -10.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _typingService = TypingIndicatorService();
    _typingService?.addListener(_onTypingStatusChanged);

    // Start infinite dots animation
    _dotsController.repeat();
  }

  @override
  void dispose() {
    _typingService?.removeListener(_onTypingStatusChanged);
    _fadeController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  void _onTypingStatusChanged() {
    if (!mounted) return;

    final isAnyoneTyping = _typingService?.isAnyoneTyping(widget.conversationId) ?? false;
    final typingText = _typingService?.getTypingText(widget.conversationId) ?? '';

    if (isAnyoneTyping != _isVisible) {
      setState(() {
        _isVisible = isAnyoneTyping;
        _currentText = typingText;
      });

      if (_isVisible) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    } else if (isAnyoneTyping && typingText != _currentText) {
      setState(() {
        _currentText = typingText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible && _fadeController.isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  _buildTypingDots(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SafeText(
                      _currentText,
                      style: widget.textStyle ?? TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingDots() {
    return SizedBox(
      width: 24,
      height: 16,
      child: AnimatedBuilder(
        animation: _dotsController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final dotOpacities = AnimationManager.typingDots(
                value: _dotsController.value,
              );
              final opacity = dotOpacities[index];

              return Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: (widget.textStyle?.color ?? Colors.grey[600])
                      ?.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }


}

/// Compact typing indicator for message tiles
class CompactTypingIndicator extends StatelessWidget {
  final String conversationId;
  final double size;
  final Color? color;

  const CompactTypingIndicator({
    super.key,
    required this.conversationId,
    this.size = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TypingIndicatorService(),
      builder: (context, child) {
        final isTyping = TypingIndicatorService().isAnyoneTyping(conversationId);

        if (!isTyping) return const SizedBox.shrink();

        return Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(left: 4),
          child: Icon(
            Icons.more_horiz,
            size: size,
            color: color ?? Colors.grey[600],
          ),
        );
      },
    );
  }
}

/// Typing indicator overlay for message input area
class MessageInputTypingOverlay extends StatelessWidget {
  final String conversationId;
  final Widget child;

  const MessageInputTypingOverlay({
    super.key,
    required this.conversationId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TypingIndicatorWidget(
          conversationId: conversationId,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          textStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        child,
      ],
    );
  }
}

/// Enhanced text field with typing indicator integration
class TypingAwareTextField extends StatefulWidget {
  final String conversationId;
  final TextEditingController controller;
  final String? hintText;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int? maxLines;

  const TypingAwareTextField({
    super.key,
    required this.conversationId,
    required this.controller,
    this.hintText,
    this.onSubmitted,
    this.onChanged,
    this.style,
    this.decoration,
    this.maxLines = 1,
  });

  @override
  State<TypingAwareTextField> createState() => _TypingAwareTextFieldState();
}

class _TypingAwareTextFieldState extends State<TypingAwareTextField> {
  late TypingIndicatorService _typingService;

  @override
  void initState() {
    super.initState();
    _typingService = TypingIndicatorService();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      style: widget.style,
      maxLines: widget.maxLines,
      decoration: widget.decoration ?? InputDecoration(
        hintText: widget.hintText,
        border: InputBorder.none,
      ),
      onChanged: (text) {
        // Handle typing indicator
        _typingService.handleTextInput(widget.conversationId, text);

        // Call original onChanged if provided
        widget.onChanged?.call(text);
      },
      onSubmitted: (text) {
        // Stop typing indicator when message is sent
        _typingService.handleMessageSent(widget.conversationId);

        // Call original onSubmitted if provided
        widget.onSubmitted?.call(text);
      },
    );
  }
}

/// Mixin for screens that need typing indicator integration
mixin TypingIndicatorMixin<T extends StatefulWidget> on State<T> {
  late TypingIndicatorService typingService;

  @override
  void initState() {
    super.initState();
    typingService = TypingIndicatorService();
  }

  /// Handle text input for typing indicator
  void handleTextInput(String conversationId, String text) {
    typingService.handleTextInput(conversationId, text);
  }

  /// Handle message sent
  void handleMessageSent(String conversationId) {
    typingService.handleMessageSent(conversationId);
  }

  /// Update typing status from network
  void updateTypingStatus({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) {
    typingService.updateUserTypingStatus(
      conversationId: conversationId,
      userId: userId,
      userName: userName,
      isTyping: isTyping,
    );
  }
}
