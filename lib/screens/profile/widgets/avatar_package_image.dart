import 'dart:io';
import 'package:flutter/material.dart';

/// Widget specifically for displaying avatar package images
///
/// Handles both:
/// - Installed packages (file paths)
/// - Bundled packages (asset paths)
class AvatarPackageImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AvatarPackageImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if this is a file path or asset path
    final isFilePath = _isFilePath(imagePath);

    Widget imageWidget;

    if (isFilePath) {
      // Use FileImage for installed packages
      imageWidget = Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[AvatarPackageImage] Error loading file: $imagePath');
          debugPrint('[AvatarPackageImage] Error: $error');
          return _buildErrorWidget();
        },
      );
    } else {
      // Use AssetImage for bundled packages
      imageWidget = Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[AvatarPackageImage] Error loading asset: $imagePath');
          debugPrint('[AvatarPackageImage] Error: $error');
          return _buildErrorWidget();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  bool _isFilePath(String path) {
    return path.startsWith('/') ||
        path.contains('/data/user/') ||
        path.contains('/storage/emulated/') ||
        path.startsWith('file://');
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

/// Grid tile for avatar selection
class AvatarPackageGridTile extends StatelessWidget {
  final String imagePath;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? label;

  const AvatarPackageGridTile({
    super.key,
    required this.imagePath,
    this.isSelected = false,
    this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AvatarPackageImage(
                  imagePath: imagePath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (label != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Text(
                  label!,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
