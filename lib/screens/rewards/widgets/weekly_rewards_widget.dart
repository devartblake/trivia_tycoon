import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../ui_components/tycoon_toast/tycoon_toast_helper.dart';

class WeeklyRewardsWidget extends StatelessWidget {
  const WeeklyRewardsWidget({super.key});

  void _claimDayReward(BuildContext context, int day, String rewardType, String amount, bool canClaim) {
    if (!canClaim) {
      // Show info toast for locked rewards
      TycoonToastHelper.createInformation(
        title: 'Reward Locked',
        message: 'Complete Day ${day - 1} to unlock this reward',
        duration: Duration(seconds: 2),
      ).show(context);
      return;
    }

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Show the reward toast
    TycoonToastHelper.createWeeklyReward(
      day: day,
      rewardType: rewardType,
      rewardAmount: amount,
      duration: Duration(seconds: 4),
    ).show(context);

    // Here you would typically update the reward state
    // For now, we'll just show the notification
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                SizedBox(width: 8),
                Text(
                  'Weekly Rewards',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Day 3/7',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // First row - Days 1, 2, 3
            Row(
              children: [
                Expanded(child: _buildDayCard(1, 'Coins', '100', Icons.monetization_on, Colors.amber, true)),
                SizedBox(width: 6),
                Expanded(child: _buildDayCard(2, 'Gems', '5', Icons.diamond, Colors.blue, true)),
                SizedBox(width: 6),
                Expanded(child: _buildDayCard(3, 'Boost', '1x', Icons.flash_on, Colors.orange, true)),
              ],
            ),

            SizedBox(height: 4),

            // Second row - Days 4, 5, 6
            Row(
              children: [
                Expanded(child: _buildDayCard(4, 'Coins', '200', Icons.monetization_on, Colors.amber, false)),
                SizedBox(width: 6),
                Expanded(child: _buildDayCard(5, 'Gems', '10', Icons.diamond, Colors.blue, false)),
                SizedBox(width: 6),
                Expanded(child: _buildDayCard(6, 'Spins', '3', Icons.casino, Colors.purple, false)),
              ],
            ),

            SizedBox(height: 4),

            // Third row - Day 7 (large card)
            _buildDay7Card(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(int day, String rewardType, String amount, IconData icon, Color color, bool claimed) {
    // Determine if this card can be claimed (for demo purposes, days 1-3 are claimed, day 4 is claimable)
    bool canClaim = day == 4 && !claimed; // Day 4 is ready to claim
    bool isLocked = day > 4; // Days 5+ are locked

    return Builder(
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => _claimDayReward(
            context,
            day,
            rewardType,
            amount,
            canClaim || claimed,
          ),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: claimed
                  ? color.withOpacity(0.1)
                  : canClaim
                  ? color.withOpacity(0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: claimed
                    ? color.withOpacity(0.3)
                    : canClaim
                    ? color.withOpacity(0.4)
                    : Colors.grey.shade300,
                width: claimed || canClaim ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Claimed checkmark
                if (claimed)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Available indicator for claimable rewards
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
                      child: Icon(
                        Icons.star,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Main content
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: claimed || canClaim
                              ? color.withOpacity(0.2)
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 16,
                          color: claimed || canClaim
                              ? color
                              : Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Day $day',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: claimed || canClaim
                              ? color
                              : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: claimed || canClaim
                              ? color
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDay7Card() {
    return Builder(
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => _claimDayReward(
            context,
            7,
            'Mystery Box',
            '1',
            false, // Day 7 is locked
          ),
          child: Container(
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade400,
                  Colors.pink.shade400,
                  Colors.orange.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BackgroundPatternPainter(),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Left side - Day info
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
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
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center - Reward info
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.card_giftcard,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Mystery Box',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right side - Lock/Status
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '4 days',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
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
      },
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw diagonal lines pattern
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