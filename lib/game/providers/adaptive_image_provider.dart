import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Adaptive Image Provider that handles both assets and file paths
///
/// Automatically detects whether a path is:
/// - An asset path (assets/...)
/// - A file path (/data/user/0/... or file://...)
/// - A network URL (http:// or https://)
class AdaptiveImageProvider {
  /// Get the appropriate ImageProvider based on the path
  static ImageProvider getProvider(String path) {
    // Handle null or empty paths
    if (path.isEmpty) {
      return const AssetImage('assets/images/placeholder.png');
    }

    // Network images
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }

    // File paths (absolute paths or file:// URIs)
    if (path.startsWith('/') ||
        path.startsWith('file://') ||
        path.contains('/data/user/') ||
        path.contains('/storage/emulated/')) {
      // Remove file:// prefix if present
      final cleanPath = path.replaceFirst('file://', '');
      return kIsWeb
          ? const AssetImage('assets/images/avatar_placeholder.png')
              as ImageProvider
          : FileImage(File(cleanPath));
    }

    // Default to AssetImage for relative paths
    return AssetImage(path);
  }

  /// Widget wrapper for adaptive images
  static Widget image(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image(
      image: getProvider(path),
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;

        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _defaultErrorWidget();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return placeholder ?? _defaultPlaceholder();
      },
    );
  }

  /// Circle avatar with adaptive image
  static Widget circleAvatar(
    String path, {
    double radius = 20,
    Color backgroundColor = Colors.grey,
  }) {
    if (path.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(
          Icons.person,
          size: radius,
          color: Colors.white,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: getProvider(path),
    );
  }

  static Widget _defaultPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  static Widget _defaultErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// Extension for easy usage
extension AdaptiveImageExtension on String {
  ImageProvider get imageProvider => AdaptiveImageProvider.getProvider(this);

  Widget toImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return AdaptiveImageProvider.image(
      this,
      width: width,
      height: height,
      fit: fit,
    );
  }

  Widget toCircleAvatar({double radius = 20}) {
    return AdaptiveImageProvider.circleAvatar(this, radius: radius);
  }
}
