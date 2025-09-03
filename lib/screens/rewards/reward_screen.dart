import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/spin_wheel.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final bool _hasClaimedToday = false;

  @override
  void initState() {
    super.initState();
    _checkDailyClaimStatus();
  }

  Future<bool> _checkDailyClaimStatus() async {
    final lastClaimDate = await AppSettings.getString('lastClaim');
    if (lastClaimDate == null) return false;

    final lastDate = DateTime.tryParse(lastClaimDate);
    final now = DateTime.now();

    return lastDate != null &&
        lastDate.year == now.year &&
        lastDate.month == now.month &&
        lastDate.day == now.day;
  }

  Future<void> _markRewardClaimed() async {
    final now = DateTime.now().toIso8601String();
    await AppSettings.setString('lastClaim', now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildDailyClaimBox(),
          const SizedBox(height: 10),
          const Center(
            child: Text('🎯 Try Your Luck!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
              builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final wheelHeight = screenWidth * 0.75;
              return SizedBox(
                height: wheelHeight,
                child: const WheelScreen(), // ✅ Plugs in your custom widget
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Games'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in), label: 'Winners'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Tournaments'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewards'),
        ],
      ),
    );
  }

  Widget _buildDailyClaimBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.yellowAccent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      child: Column(
        children: [
          const Text("🎁 Daily Mystery Box", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _hasClaimedToday
              ? const Text("✅ You've already claimed your daily reward.", style: TextStyle(color: Colors.green))
              : ElevatedButton(
            onPressed: _markRewardClaimed,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text("Claim Now"),
          ),
        ],
      ),
    );
  }
}
