import 'package:flutter/material.dart';

class SlimyImagePreview extends StatelessWidget {
  final String imageAsset;
  final double height;

  const SlimyImagePreview({
    super.key,
    required this.imageAsset,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: precacheImage(AssetImage(imageAsset), context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: Image.asset(
              imageAsset,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: height,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          );
        } else {
          return Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade100],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          );
        }
      },
    );
  }
}
