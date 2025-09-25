import 'package:flutter/material.dart';

enum VersusMode { oneVone, teamVteam }

class Participant {
  final String id;
  final String displayName;          // Player or Team name
  final String? subtitle;            // Tagline, rank, MMR, etc.
  final String? avatarUrl;           // Team logo or player avatar
  final Color? color;                // Accent color
  final List<Member> members;        // Empty or [single] for 1v1; multiple for teams
  final bool isHost;

  const Participant({
    required this.id,
    required this.displayName,
    this.subtitle,
    this.avatarUrl,
    this.color,
    this.members = const [],
    this.isHost = false,
  });

  bool get isTeam => members.length > 1;
}

class Member {
  final String id;
  final String name;
  final String? avatarUrl;

  const Member({required this.id, required this.name, this.avatarUrl});
}

class VersusConfig {
  final VersusMode mode;
  final Participant left;
  final Participant right;
  final String? seriesLabel;     // e.g., "Best of 3", "Final"
  final String? mapOrCategory;   // optional meta (e.g., “General Knowledge”)
  final Duration introDuration;  // total anim time
  final bool showReadyBadges;    // if you have ready states later

  const VersusConfig({
    required this.mode,
    required this.left,
    required this.right,
    this.seriesLabel,
    this.mapOrCategory,
    this.introDuration = const Duration(milliseconds: 2000),
    this.showReadyBadges = false,
  });
}
