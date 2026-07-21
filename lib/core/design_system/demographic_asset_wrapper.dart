import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/synaptix/mode/synaptix_mode.dart';
import 'package:synaptix/synaptix/mode/synaptix_mode_provider.dart';

/// A smart component that swaps assets based on the user's demographic age group.
class DemographicAssetWrapper extends ConsumerWidget {
  final String kidsAsset;
  final String teenAsset;
  final String adultAsset;
  final double? width;
  final double? height;
  final BoxFit fit;

  const DemographicAssetWrapper({
    super.key,
    required this.kidsAsset,
    required this.teenAsset,
    required this.adultAsset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(synaptixModeProvider);
    
    final String resolvedAsset = switch (mode) {
      SynaptixMode.kids => kidsAsset,
      SynaptixMode.teen => teenAsset,
      SynaptixMode.adult => adultAsset,
    };

    if (resolvedAsset.endsWith('.json')) {
      // Placeholder for Lottie implementation if needed
      return const SizedBox.shrink();
    }

    return Image.asset(
      resolvedAsset,
      width: width,
      height: height,
      fit: fit,
      // Ensure we don't crash if an asset is missing during development
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.broken_image_rounded,
        size: width ?? 24,
        color: Colors.white24,
      ),
    );
  }
}
