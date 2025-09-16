import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trivia_tycoon/game/models/leaderboard_entry.dart';
import 'package:trivia_tycoon/screens/leaderboard/widgets/shimmer_avatar.dart';
import '../../ui_components/qr_code/widgets/qr_code_widget.dart';

class UserProfileScreen extends StatelessWidget {
  final LeaderboardEntry entry;

  const UserProfileScreen({super.key, required this.entry});

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  Widget _buildFlag(String? code) {
    if (code == null || code.isEmpty) return const SizedBox.shrink();
    final codeUnits = code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + (c - 65));
    return Text(String.fromCharCodes(codeUnits), style: const TextStyle(fontSize: 20));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winRate = (entry.accuracy ?? 0.6).clamp(0.0, 1.0);
    final lossRate = 1 - winRate;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.deepPurple,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.deepPurple,
                    tabs: [
                      Tab(text: "Statistic"),
                      Tab(text: "Settings"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStatsTab(winRate, lossRate),
                        const Center(child: Text("Settings coming soon...")),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      // Add this FloatingActionButton to the Scaffold:
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => _buildShareModal(context),
          );
        },
        child: const Icon(Icons.share),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ShimmerAvatar(
                    avatarPath: entry.avatar,
                    initials: entry.playerName[0].toUpperCase(),
                    radius: 44,
                    xpProgress: entry.xpProgress,
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)],
                      ),
                      child: Text(
                        String.fromCharCodes(
                          entry.country.toUpperCase().codeUnits.map((c) => 0x1F1E6 + (c - 65)),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              /*const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: Icon(Icons.edit, size: 16),
              ),*/
            ],
          ),
          const SizedBox(height: 12),
          Text(entry.playerName, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text("Share Profile", style: TextStyle(color: Colors.white70)),
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Scan or Share", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        // Placeholder for QR Code widget
                        const FlutterLogo(size: 120),
                        const SizedBox(height: 16),
                        Text("User ID: ${entry.userId}"),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text("Share Profile"),
                          onPressed: () {
                            // Implement share logic
                          },
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFlag(entry.country),
                      const SizedBox(width: 6),
                      Text(entry.country, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("ID: #${entry.userId}", style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          Text("${entry.ageGroup.toUpperCase()} • Level ${entry.level}"),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text("870", style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                  const Text("Following", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Container(
                height: 28,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white24,
              ),
              Column(
                children: [
                  Text("1.2K", style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                  const Text("Followers", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Container(
                height: 28,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white24,
              ),
              Column(
                children: [
                  Text("328", style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                  const Text("Questions", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(double winRate, double lossRate) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Win Rate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Wins"),
            Text("Losses"),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            LinearProgressIndicator(
              value: winRate,
              backgroundColor: Colors.redAccent,
              color: Colors.green,
              minHeight: 12,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${(winRate * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.green)),
            Text("${(lossRate * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Profile Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              _infoTile("Title", entry.title),
              _infoTile("Rank", "#${entry.rank}"),
              _infoTile("Last Active", _formatDate(entry.lastActive)),
              _infoTile("Account Status", entry.accountStatus),
              _infoTile("Subscription", entry.subscriptionStatus),
              _infoTile("Notification", entry.preferredNotificationMethod),
              _infoTile("Engagement Score", entry.engagementScore.toStringAsFixed(1)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Match History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TextButton(onPressed: () {}, child: const Text("View All")),
          ],
        ),
        const SizedBox(height: 8),
        _buildMatchTile("Dimas", "Arlene", 92, 31, true),
        _buildMatchTile("Dimas", "Daniel", 20, 64, false),
      ],
    );
  }

  Widget _buildMatchTile(String player1, String player2, int score1, int score2, bool win) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: win ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/images/avatars/default-avatar.png')),
          const SizedBox(width: 10),
          Expanded(child: Text(player1, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(score1.toString()),
          const SizedBox(width: 8),
          const Icon(Icons.score, size: 16),
          const SizedBox(width: 8),
          Text(score2.toString()),
          const SizedBox(width: 10),
          Expanded(child: Text(player2, textAlign: TextAlign.right)),
          const SizedBox(width: 10),
          const CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/images/avatars/default-avatar.png')),
        ],
      ),
    );
  }

  // Helper widget
  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Bottom sheet for QR/share
  Widget _buildShareModal(BuildContext context) {
    final shareUrl = 'https://trivia-tycoon.com/user/${entry.userId}';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Share Profile", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),

          // ✅ Replace placeholder with QR Code
          QrCodeWidget(
            data: shareUrl,
            size: 160,
            dotColor: Colors.deepPurple,
            backgroundColor: Colors.white,
            roundedDots: true,
            padding: 8.0,
          ),

          const SizedBox(height: 12),
          Text("Username: @${entry.playerName}"),
          Text("User ID: #${entry.userId}"),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text("Copy Link"),
            onPressed: () {
              // Clipboard.setData(ClipboardData(text: "..."));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class UserInfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const UserInfoTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
