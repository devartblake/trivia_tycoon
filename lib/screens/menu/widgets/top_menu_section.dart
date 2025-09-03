import 'package:flutter/material.dart';

class TopMenuSection extends StatelessWidget {
  const TopMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/images/avatars/default-avatar.png'), // Change to user profile pic
            ),
            const SizedBox(width: 12),
            const Text(
              'Username',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRectangularButton(Icons.play_arrow, "Play Quiz"),
            _buildRectangularButton(Icons.create, "Create Quiz"),
            _buildRectangularButton(Icons.emoji_events, "Achievements"),
          ],
        ),
      ],
    );
  }

  Widget _buildRectangularButton(IconData icon, String label) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.blueAccent,
        ),
        onPressed: () {},
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.white),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
