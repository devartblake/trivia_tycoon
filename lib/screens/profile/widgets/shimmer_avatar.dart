import 'dart:io';

import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

class ShimmerAvatar extends StatelessWidget {
  final String? avatarPath;
  final bool isOnline;
  final bool isLoading;
  final double radius;

  const ShimmerAvatar({
    super.key,
    required this.avatarPath,
    this.isOnline = true,
    this.isLoading = false,
    this.radius = 36, // Default Radius
  });

  @override
  Widget build(BuildContext context) {
    final avatar = avatarPath != null && avatarPath!.isNotEmpty
        ? (avatarPath!.startsWith('assets/')
        ? Image.asset(avatarPath!, fit: BoxFit.cover, width: 60, height: 60)
        : Image.file(File(avatarPath!), fit: BoxFit.cover, width: 60, height: 60))
        : Image.asset('assets/images/avatars/default-avatar.jpg', fit: BoxFit.cover, width: 60, height: 60);

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade200,
          child: ClipOval(
            child: isLoading
                ? Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.white,
              child: Container(width: 60, height: 60, color: Colors.grey),
            )
                : avatar,
          ),
        ),

        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: radius * 0.4,
            height: radius * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? Colors.green : Colors.red,
              border: Border.all(color: Colors.white, width: radius * 0.08),
            ),
          ),
        ),
      ],
    );
  }
}