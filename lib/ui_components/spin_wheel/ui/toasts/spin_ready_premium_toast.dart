import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../tycoon_toast/tycoon_toast.dart';

/// Premium version with more features
class PremiumSpinReadyToast {
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onSpinNow,
    int? spinsRemaining,
    int? rewardPoints,
    String? bonusMessage,
  }) async {
    final toast = TycoonToast(
      title: '🎰 Free Spin Available!',
      message: _buildMessage(spinsRemaining, rewardPoints, bonusMessage),
      icon: _buildAnimatedIcon(),
      toastType: TycoonToastType.reward,
      tycoonToastPosition: TycoonToastPosition.bottom,
      tycoonToastStyle: TycoonToastStyle.floating,
      themeEvent: 'premium_spin_ready',
      isDismissible: true,
      shouldIconPulse: true,
      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      animationDuration: const Duration(milliseconds: 1000),
      forwardAnimationCurve: Curves.elasticOut,
      reverseAnimationCurve: Curves.easeInBack,
      mainButton: _buildPremiumButton(onSpinNow, context, spinsRemaining),
      onTap: (toast) {
        toast.dismiss();
        onSpinNow();
      },
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFF6B35).withValues(alpha: 0.95),
          const Color(0xFFF7931E).withValues(alpha: 0.95),
          const Color(0xFFFFC837).withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      boxShadows: [
        BoxShadow(
          color: const Color(0xFFFFA500).withValues(alpha: 0.6),
          blurRadius: 30,
          spreadRadius: 8,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      leftBarIndicatorColor: const Color(0xFFFFD700),
    );

    await toast.show(context);
  }

  static String _buildMessage(
      int? spinsRemaining, int? rewardPoints, String? bonusMessage) {
    final parts = <String>[];

    if (spinsRemaining != null) {
      parts.add('$spinsRemaining spins left today');
    }

    if (rewardPoints != null) {
      parts.add('$rewardPoints reward points earned');
    }

    if (bonusMessage != null) {
      parts.add(bonusMessage);
    }

    return parts.isNotEmpty
        ? parts.join(' • ')
        : 'Tap to spin the wheel and win amazing rewards!';
  }

  static Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 2 * math.pi),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.casino,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
      onEnd: () {
        // Loop animation
      },
    );
  }

  static Widget _buildPremiumButton(
      VoidCallback onTap, BuildContext context, int? spinsRemaining) {
    return Column(
      children: [
        if (spinsRemaining != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00FF00),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$spinsRemaining Spins Available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFFA500),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(0, 6),
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
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.casino,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SPIN NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
