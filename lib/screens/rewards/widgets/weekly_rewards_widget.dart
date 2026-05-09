import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui_components/synaptix_toast/synaptix_toast_helper.dart';

class WeeklyRewardsWidget extends ConsumerStatefulWidget {
  const WeeklyRewardsWidget({super.key});

  void _claimDayReward(BuildContext context, int day, String rewardType,
      String amount, bool canClaim) {
    if (!canClaim) {
      // Show info toast for locked rewards
      SynaptixToastHelper.createInformation(
        title: 'Reward Locked',
        message: 'Complete Day ${day - 1} to unlock this reward',
        duration: Duration(seconds: 2),
      ).show(context);
      return;
    }

    HapticFeedback.mediumImpact();

    // Show the reward toast
    SynaptixToastHelper.createWeeklyReward(
      day: day,
      rewardType: 'Coins',
      rewardAmount: coinsEarned.toString(),
      duration: const Duration(seconds: 4),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final nextClaimableDay = _claimedThroughDay + 1;
    final dayText =
        _claimedThroughDay > 0 ? 'Day $_claimedThroughDay/7' : 'Day 0/7';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weekly Rewards',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dayText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _buildDayCard(
                        context, 1, 'Coins', '100', Icons.monetization_on,
                        Colors.amber, nextClaimableDay)),
                const SizedBox(width: 6),
                Expanded(
                    child: _buildDayCard(context, 2, 'Gems', '5', Icons.diamond,
                        Colors.blue, nextClaimableDay)),
                const SizedBox(width: 6),
                Expanded(
                    child: _buildDayCard(context, 3, 'Boost', '1x',
                        Icons.flash_on, Colors.orange, nextClaimableDay)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                    child: _buildDayCard(
                        context, 4, 'Coins', '200', Icons.monetization_on,
                        Colors.amber, nextClaimableDay)),
                const SizedBox(width: 6),
                Expanded(
                    child: _buildDayCard(context, 5, 'Gems', '10', Icons.diamond,
                        Colors.blue, nextClaimableDay)),
                const SizedBox(width: 6),
                Expanded(
                    child: _buildDayCard(context, 6, 'Spins', '3', Icons.casino,
                        Colors.purple, nextClaimableDay)),
              ],
            ),
            const SizedBox(height: 4),
            _buildDay7Card(context, nextClaimableDay),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    int day,
    String rewardType,
    String amount,
    IconData icon,
    Color color,
    int nextClaimableDay,
  ) {
    final claimed = day <= _claimedThroughDay;
    final canClaim = _canClaimToday && day == nextClaimableDay;

    return GestureDetector(
      onTap: () => _claimDay(context, day),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: claimed
              ? color.withValues(alpha: 0.1)
              : canClaim
                  ? color.withValues(alpha: 0.15)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: claimed
                ? color.withValues(alpha: 0.3)
                : canClaim
                    ? color.withValues(alpha: 0.4)
                    : Colors.grey.shade300,
            width: claimed || canClaim ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (claimed)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
            if (canClaim)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.star, size: 10, color: Colors.white),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: claimed || canClaim
                          ? color.withValues(alpha: 0.2)
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: claimed || canClaim ? color : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Day $day',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          claimed || canClaim ? color : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          claimed || canClaim ? color : Colors.grey.shade600,
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

  Widget _buildDay7Card(BuildContext context, int nextClaimableDay) {
    final claimed = _claimedThroughDay >= 7;
    final canClaim = _canClaimToday && nextClaimableDay == 7;
    final daysLeft = 7 - _claimedThroughDay;

    return GestureDetector(
      onTap: () => _claimDay(context, 7),
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: claimed
                ? [Colors.green.shade400, Colors.green.shade600]
                : canClaim
                    ? [
                        Colors.purple.shade400,
                        Colors.pink.shade400,
                        Colors.orange.shade400,
                      ]
                    : [
                        Colors.purple.shade200,
                        Colors.pink.shade200,
                        Colors.orange.shade200,
                      ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundPatternPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'DAY 7',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'GRAND PRIZE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            claimed ? Icons.check_circle : Icons.card_giftcard,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          claimed ? 'Claimed!' : 'Mystery Box',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            claimed || canClaim ? Icons.lock_open : Icons.lock,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (!claimed)
                          Text(
                            canClaim ? 'Claim!' : '$daysLeft days',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
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
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
