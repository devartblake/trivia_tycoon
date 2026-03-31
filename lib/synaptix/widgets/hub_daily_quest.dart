import 'package:flutter/material.dart';
import '../theme/synaptix_theme_extension.dart';

/// Neo-skeuomorphic daily quest progress card for the Synaptix Hub.
///
/// Shows current quest progress with a progress bar and description.
/// Uses the GlassCard visual pattern (semi-transparent container with border).
class HubDailyQuest extends StatelessWidget {
  const HubDailyQuest({super.key});

  @override
  Widget build(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final radius = synaptix?.cardRadius ?? 16.0;

    // TODO: Replace with quest provider data
    const completed = 4;
    const total = 5;
    const progress = completed / total;
    const description = 'Answer 5 history questions to claim 50 coins.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x15FFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x22FFFFFF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF50C878), Color(0xFF3DA55C)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'DAILY QUEST',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const Text(
                '$completed/$total',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  color: Color(0xFF50C878),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: progress,
              backgroundColor: Color(0x1AFFFFFF),
              color: Color(0xFF50C878),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            description,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
