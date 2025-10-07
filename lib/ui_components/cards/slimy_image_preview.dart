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
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          child: Image.asset(
            imageAsset,
            height: height,
            fit: BoxFit.cover,
            // CRITICAL: Impeller-safe image loading
            filterQuality: FilterQuality.low,
            // Smooth fade-in animation
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;

              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                child: AnimatedScale(
                  scale: frame == null ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  child: child,
                ),
              );
            },
            // Error handling
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_rounded,
                      size: 48,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
