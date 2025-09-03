import 'package:flutter/material.dart';
import 'widgets/top_menu_section.dart';
import 'widgets/daily_quiz_widget.dart';
import 'widgets/grid_menu_section.dart';
import 'widgets/cta_widget.dart';

class GameMenuScreen extends StatelessWidget {
  const GameMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia Game'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TopMenuSection(),
            const SizedBox(height: 30),
            const DailyQuizWidget(),
            const SizedBox(height: 30),
            const GridMenuSection(),
            const SizedBox(height: 30),
            CTAWidget(
              title: "Special Offer!",
              subtitle: "Get exclusive rewards today.",
              buttonText: "Claim Now",
              onPressed: () {
                // TODO: Implement CTA Action
              },
              backgroundImage: "assets/images/cta_banner.png",
              overlayColor: Colors.black45, // Adjust transparency if needed
            ),
          ],
        ),
      ),
    );
  }
}
