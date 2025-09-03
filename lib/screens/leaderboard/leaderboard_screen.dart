import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/ui_components/mission/mission_panel.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int playerXP = 1200; // Mocked value; replace with actual user XP

  void _handleXPAdded(int xp) {
    setState(() => playerXP += xp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildTierHeader()),
          SliverToBoxAdapter(child: MissionPanel(playerXP: playerXP, onXPAdded: _handleXPAdded)),
          SliverToBoxAdapter(child: _buildSeasonRewardsTrack()),
        ],
      ),
    );
  }

  Widget _buildTierHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B1E86), Color(0xFF5A4DA2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield, size: 40, color: Colors.amberAccent),
          const SizedBox(height: 16),
          const Text("APPRENTICE I", style: TextStyle(fontSize: 20, color: Colors.white)),
          const SizedBox(height: 6),
          const Text("50  • You are currently in the safe zone", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Ends in 5d 05h", style: TextStyle(color: Colors.white)),
              Text("See ranking", style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonRewardsTrack() {
    return Container(
      color: Colors.pink.shade100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("EASTER SEASON", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Ends in 01d 04h"),
          const SizedBox(height: 16),
          _buildRewardNode("x1", Icons.check_circle, true),
          _buildRewardNode("x5000", Icons.monetization_on_outlined, false),
          _buildRewardNode("x50", Icons.card_giftcard, false),
        ],
      ),
    );
  }

  Widget _buildRewardNode(String label, IconData icon, bool claimed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: claimed ? Colors.green : Colors.grey,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
