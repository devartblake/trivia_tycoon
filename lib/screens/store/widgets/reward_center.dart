import 'package:flutter/material.dart';

// Reward Center Widget
class RewardCenter extends StatelessWidget {
  const RewardCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.white,  // Set the entire widget background to white
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
        ),
        child: Column(
          children: [
            // Reward Center Title
            Text(
              'Reward Center',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30), // Spacing between title and the reward columns

            // Reward Columns (2 different columns side by side)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Column for Option A with dark grey background
                Expanded(
                  child: _buildColumn('Option A', 'assets/images/reward-quiz.png', Colors.grey[500]!),
                ),

                SizedBox(width: 12),

                // Column for Option B with dark grey background
                Expanded(
                  child: _buildColumn('Option B', 'assets/images/reward-quiz.png', Colors.grey[500]!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Column builder with image above the button and text below the button
  Widget _buildColumn(String title, String imagePath, Color color) {
    return Column(
      children: [
        // Container to take up full width with dark grey background
        Container(
          width: double.infinity,  // Ensure the container takes up the full width
          decoration: BoxDecoration(
            color: color,  // Dark grey background color
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
          ),
          child: Column(
            children: [
              // Image above the button
              Image.asset(
                imagePath, // Image path for the reward
                width: 80,
                height: 80,
                // Ensure the image is available
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, size: 80);  // Fallback in case the image is missing
                },
              ),

              SizedBox(height: 12),  // Spacing between button and text

              // Text below the button
              Text(
                title,  // Title text below the button
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
