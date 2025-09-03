import 'package:flutter/material.dart';
import '../../ui_components/cards/slimy_card.dart';
import '../../ui_components/cards/slimy_image_preview.dart';

class SlimyCardPreviewScreen extends StatelessWidget {
  const SlimyCardPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slimy Card Preview')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SlimyCard(
            topChild: const SlimyImagePreview(
              imageAsset:'assets/images/cta_banner.png',
              height: 180,
            ),
            bottomChild: const Text('This vault unlock splash glows and emits particles.'),
            badgeText: 'Featured',
            backgroundGradient: const LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            blurAmount: 4.0,
          ),
          const SizedBox(height: 20),
          SlimyCard(
            topChild: const Icon(Icons.flash_on, size: 90, color: Colors.orange),
            bottomChild: const Text('Power up your trivia experience.'),
            badgeText: 'New',
            badgeColor: Colors.orange,
            backgroundGradient: const LinearGradient(
              colors: [Colors.indigo, Colors.lightBlueAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ],
      ),
    );
  }
}