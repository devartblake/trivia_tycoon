import 'package:flutter/material.dart';

enum AlertType {
  warning,
  error,
  success,
  info,
  delete,
}

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final AlertType type;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showCancelButton;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = AlertType.info,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.showCancelButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Section
            Container(
              margin: const EdgeInsets.only(top: 32, bottom: 24),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor().withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getIcon(),
                    color: _getIconBackgroundColor(),
                    size: 40,
                  ),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 12),

            // Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (showCancelButton) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (onCancel != null) {
                            onCancel!();
                          }
                          Navigator.of(context).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          cancelText ?? 'Cancel',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (onConfirm != null) {
                          onConfirm!();
                        }
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        confirmText ?? _getDefaultConfirmText(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case AlertType.warning:
        return Icons.warning_rounded;
      case AlertType.error:
        return Icons.error_rounded;
      case AlertType.success:
        return Icons.check_circle_rounded;
      case AlertType.info:
        return Icons.info_rounded;
      case AlertType.delete:
        return Icons.delete_rounded;
    }
  }

  Color _getIconBackgroundColor() {
    switch (type) {
      case AlertType.warning:
        return const Color(0xFFF59E0B);
      case AlertType.error:
      case AlertType.delete:
        return const Color(0xFFEF4444);
      case AlertType.success:
        return const Color(0xFF10B981);
      case AlertType.info:
        return const Color(0xFF3B82F6);
    }
  }

  Color _getButtonColor() {
    switch (type) {
      case AlertType.warning:
        return const Color(0xFFF59E0B);
      case AlertType.error:
      case AlertType.delete:
        return const Color(0xFFEF4444);
      case AlertType.success:
        return const Color(0xFF10B981);
      case AlertType.info:
        return const Color(0xFF3B82F6);
    }
  }

  String _getDefaultConfirmText() {
    switch (type) {
      case AlertType.warning:
        return 'Continue';
      case AlertType.error:
        return 'OK';
      case AlertType.success:
        return 'OK';
      case AlertType.info:
        return 'OK';
      case AlertType.delete:
        return 'Delete';
    }
  }
}

// Helper function to show the dialog
Future<bool?> showCustomAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  AlertType type = AlertType.info,
  String? confirmText,
  String? cancelText,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool showCancelButton = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CustomAlertDialog(
      title: title,
      message: message,
      type: type,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      showCancelButton: showCancelButton,
    ),
  );
}
