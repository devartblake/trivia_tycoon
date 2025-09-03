import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/menu/widgets/app_drawer.dart';
import '../../screens/menu/widgets/rank_level_card.dart';
import '../../screens/menu/widgets/recently_played_section.dart';
import '../../screens/menu/widgets/user_greeting_appbar.dart';
import '../profile/widgets/shimmer_avatar.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // User Details
    final String userName = 'John Doe';
    final String ageGroup = 'teens';
    final String rank = 'Trivia Master';
    final int level = 12;
    final int currentXP = 340;
    final int maxXP = 500;

    // Recently played quizzes
    final List<Map<String, String>> recentlyPlayedQuizzes = [
      {'title': 'Science Trivia', 'score': '85%', 'date': 'March 5', 'image': 'assets/images/quiz/category/science.jpg'},
      {'title': 'History Quiz', 'score': '90%', 'date': 'March 4', 'image': 'assets/images/quiz/category/cinema.jpg'},
      {'title': 'Pop Culture', 'score': '75%', 'date': 'March 3', 'image': 'assets/images/quiz/category/pop_culture.jpg'},
      {'title': '1980 Movies', 'score': '25%', 'date': 'February 28', 'image': 'assets/images/quiz/category/film-strip.jpg'},
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: UserGreetingAppBar(
        userName: userName,
        ageGroup: ageGroup,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank & Level Widget
            RankLevelCard(
              rank: rank,
              level: level,
              currentXP: currentXP,
              maxXP: maxXP,
              ageGroup: ageGroup,
            ),
            const SizedBox(height: 20),

            // Action Buttons Row (Invite, Rewards, Discounts)
            _ActionButtonsRow(ageGroup: ageGroup),

            const SizedBox(height: 20),

            // Trivia Progress Card
            _TriviaJourneyProgress(currentXP: currentXP, maxXP: maxXP),

            const SizedBox(height: 20),

            // Recently Played Quizzes Section
            RecentlyPlayedSection(quizzes: recentlyPlayedQuizzes, ageGroup: ageGroup),

            const SizedBox(height: 20),

            // User Matches Section
            _MatchesSection(),
          ],
        ),
      ),
    );
  }
}

/// Action Buttons Row (Modularized)
class _ActionButtonsRow extends StatelessWidget {
  final String ageGroup;

  const _ActionButtonsRow({required this.ageGroup});

  @override
  Widget build(BuildContext context) {
    final Color accentColor = ageGroup == 'teens' ? Colors.blueAccent : Colors.orangeAccent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton('Invite Friends', Icons.people, accentColor),
        _ActionButton('Quick Rewards', Icons.redeem, accentColor),
        _ActionButton('Discount', Icons.local_offer, accentColor),
        _ActionButton('Ladder', Icons.account_tree, accentColor),
        _ActionButton('Gift', Icons.card_giftcard, accentColor),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ActionButton(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// Trivia Journey Progress Card (Modularized)
class _TriviaJourneyProgress extends StatelessWidget {
  final int currentXP;
  final int maxXP;

  const _TriviaJourneyProgress({required this.currentXP, required this.maxXP});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trivia Journey', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: currentXP / maxXP),
                  const SizedBox(height: 8),
                  Text('$currentXP / $maxXP XP', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              width: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('50% OFF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Matches Section (Modularized)
class _MatchesSection extends StatelessWidget {
  final matches = const [
    {
      'name': 'mindpixell',
      'score': '0-0',
      'time': '1d left',
      'avatar': 'assets/images/avatars/avatar-1.png',
    },
    {
      'name': 'giovanni.rasmussen',
      'score': '3-0',
      'time': '1d left',
      'avatar': 'assets/images/avatars/avatar-2.png',
    },
    {
      'name': 'dexter.henderson',
      'score': '0-1',
      'time': '1d left',
      'avatar': 'assets/images/avatars/avatar-3.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...matches.map((match) => ListTile(
          leading: ShimmerAvatar(
            avatarPath: match['avatar']!,
            //radius: 22,
            isOnline: true,
            isLoading: false,
          ),
          title: Text(match['name']!),
          subtitle: Text(match['score']!),
          trailing: Text(match['time']!),
          onTap: () => context.push('/match-details', extra: match),
        )),
      ],
    );
  }
}
