import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/tycoon_toast/tycoon_toast.dart';
import 'dart:math' as math;

class SpinReadyToast {
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onSpinNow,
    String? customMessage,
  }) async {
    final toast = TycoonToast(
      title: '🎰 Spin Ready!',
      message: customMessage ?? 'Your spin is available. Tap to spin now!',
      icon: _buildSpinIcon(),
      toastType: TycoonToastType.reward,
      tycoonToastPosition: TycoonToastPosition.bottom,
      tycoonToastStyle: TycoonToastStyle.floating,
      themeEvent: 'spin_ready',
      isDismissible: true,
      shouldIconPulse: true,
      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      animationDuration: const Duration(milliseconds: 800),
      forwardAnimationCurve: Curves.elasticOut,
      reverseAnimationCurve: Curves.easeInBack,
      soundEffect: 'assets/sounds/spin_ready.mp3', // Optional
      mainButton: _buildSpinButton(onSpinNow, context),
      onTap: (toast) {
        toast.dismiss();
        onSpinNow();
      },
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFA500).withValues(alpha: 0.9),
          const Color(0xFFFF6B35).withValues(alpha: 0.9),
        ],
      ),
      boxShadows: [
        BoxShadow(
          color: const Color(0xFFFFA500).withValues(alpha: 0.5),
          blurRadius: 25,
          spreadRadius: 5,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );

    await toast.show(context);
  }

  static Widget _buildSpinIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.casino,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  static Widget _buildSpinButton(VoidCallback onTap, BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.casino,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'SPIN NOW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
