import 'package:flutter/material.dart';
import '../../../ui_components/depth_card_3d/depth_card.dart';

class TryNowWidget extends StatelessWidget {
  final String modelPath;
  final String title;

  const TryNowWidget({
    super.key,
    required this.modelPath,
    this.title = 'Try Now',
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('📦 TryNowWidget building...');
    debugPrint('🔍 Model path received: $modelPath');
    return Center(
      child: DepthCard3D(
        config: DepthCardConfig(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 300,
          text: title,
          backgroundImage: const AssetImage('assets/images/backgrounds/geometry_background.jpg'),
          modelAssetPath: modelPath,
          borderRadius: 16.0,
          parallaxDepth: 5.0,
          overlayActions: [
            CardOverlayAction(
              icon: Icons.touch_app,
              tooltip: "Interact",
              onPressed: () => debugPrint("$title pressed"),
            ),
          ],
          theme: const DepthCardTheme(
            glowEnabled: true,
            shadowColor: Colors.tealAccent,
            overlayColor: Colors.black38,
            textColor: Colors.white,
            elevation: 10,
          ),
        ),
      ),
    );
  }
}
