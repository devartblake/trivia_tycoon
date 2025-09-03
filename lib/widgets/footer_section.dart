import 'package:flutter/material.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Follow us on social media',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.facebook),
                onPressed: () {}, // Open Facebook
              ),
              IconButton(
                icon: const Icon(Icons.web),
                onPressed: () {}, // Open Website
              ),
            ],
          ),
        ],
      ),
    );
  }
}
