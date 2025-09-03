import 'package:flutter/material.dart';

class AgeSelectionScreen extends StatelessWidget {
  const AgeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Age Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Option for Kids
            _buildAgeOptionCard(context, 'Kids (7-13)', 'Fun and playful quizzes', Icons.child_care, Colors.pinkAccent, ageGroup: 'kids'),
            SizedBox(height: 16),
            // Option for Teenagers
            _buildAgeOptionCard(context, 'Teenagers (14-18)', 'Challenging and fast-paced', Icons.school, Colors.blueAccent, ageGroup: 'teens'),
            SizedBox(height: 16),
            // Option for Adults
            _buildAgeOptionCard(context, 'Adults (18+)', 'In-depth and intellectual', Icons.person, Colors.green, ageGroup: 'adults'),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeOptionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, {required String ageGroup}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Save the selected age group and navigate to the main menu.
          // For example, using Hive or a state management solution.
          // Hive.box('settings').put('age_group', ageGroup);
          Navigator.pushReplacementNamed(context, '/main_menu');
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
