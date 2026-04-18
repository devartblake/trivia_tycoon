import 'package:flutter/material.dart';
import 'store_hub_model.dart';

/// Maps a color name or hex string to a [Color].
Color resolveColor(String? value, {Color fallback = const Color(0xFF6366F1)}) {
  if (value == null || value.isEmpty) return fallback;
  switch (value) {
    case 'green':
      return const Color(0xFF10B981);
    case 'yellow':
    case 'amber':
      return const Color(0xFFF59E0B);
    case 'red':
      return const Color(0xFFEF4444);
    case 'purple':
      return const Color(0xFF8B5CF6);
    case 'blue':
      return const Color(0xFF6366F1);
    case 'pink':
      return const Color(0xFFEC4899);
    default:
      try {
        final clean = value.startsWith('#') ? value.substring(1) : value;
        return Color(int.parse(clean.padLeft(8, 'F'), radix: 16) | 0xFF000000);
      } catch (_) {
        return fallback;
      }
  }
}

// ---------------------------------------------------------------------------
// Received Gifts
// ---------------------------------------------------------------------------

class ReceivedGift {
  final String id;
  final String from;
  final String? avatarUrl;
  final String giftName;
  final IconData icon;
  final Color color;
  final String timeLabel;
  final String? message;
  final bool claimed;

  const ReceivedGift({
    required this.id,
    required this.from,
    this.avatarUrl,
    required this.giftName,
    required this.icon,
    required this.color,
    required this.timeLabel,
    this.message,
    required this.claimed,
  });

  factory ReceivedGift.fromJson(Map<String, dynamic> json) {
    return ReceivedGift(
      id: json['id'] as String? ?? '',
      from: json['from'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      giftName: json['giftName'] as String? ?? '',
      icon: resolveIcon(json['icon'] as String?, fallback: Icons.card_giftcard),
      color: resolveColor(json['color'] as String?),
      timeLabel: json['timeLabel'] as String? ?? '',
      message: json['message'] as String?,
      claimed: json['claimed'] as bool? ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// Sendable Gifts
// ---------------------------------------------------------------------------

class SendableGift {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String cost;

  const SendableGift({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.cost,
  });

  factory SendableGift.fromJson(Map<String, dynamic> json) {
    return SendableGift(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: resolveIcon(json['icon'] as String?, fallback: Icons.card_giftcard),
      color: resolveColor(json['color'] as String?),
      cost: json['cost'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Gift History
// ---------------------------------------------------------------------------

class GiftHistoryItem {
  final String id;
  final String type;
  final String to;
  final String from;
  final String giftName;
  final IconData icon;
  final Color color;
  final String timeLabel;
  final String status;

  const GiftHistoryItem({
    required this.id,
    required this.type,
    required this.to,
    required this.from,
    required this.giftName,
    required this.icon,
    required this.color,
    required this.timeLabel,
    required this.status,
  });

  factory GiftHistoryItem.fromJson(Map<String, dynamic> json) {
    return GiftHistoryItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'sent',
      to: json['to'] as String? ?? '',
      from: json['from'] as String? ?? '',
      giftName: json['giftName'] as String? ?? '',
      icon: resolveIcon(json['icon'] as String?, fallback: Icons.card_giftcard),
      color: resolveColor(json['color'] as String?),
      timeLabel: json['timeLabel'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Gift Stats
// ---------------------------------------------------------------------------

class GiftStats {
  final String received;
  final String sent;
  final String pending;

  const GiftStats({
    required this.received,
    required this.sent,
    required this.pending,
  });

  factory GiftStats.fromJson(Map<String, dynamic> json) {
    return GiftStats(
      received: json['received']?.toString() ?? '0',
      sent: json['sent']?.toString() ?? '0',
      pending: json['pending']?.toString() ?? '0',
    );
  }
}

// ---------------------------------------------------------------------------
// Aggregate
// ---------------------------------------------------------------------------

class GiftsData {
  final GiftStats stats;
  final List<ReceivedGift> received;
  final List<SendableGift> available;
  final List<GiftHistoryItem> history;

  const GiftsData({
    required this.stats,
    required this.received,
    required this.available,
    required this.history,
  });

  factory GiftsData.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'] as Map<String, dynamic>? ?? {};
    final rawReceived = json['received'] as List? ?? [];
    final rawAvailable = json['available'] as List? ?? [];
    final rawHistory = json['history'] as List? ?? [];

    return GiftsData(
      stats: GiftStats.fromJson(rawStats),
      received: rawReceived
          .whereType<Map>()
          .map((g) => ReceivedGift.fromJson(Map<String, dynamic>.from(g)))
          .toList(),
      available: rawAvailable
          .whereType<Map>()
          .map((g) => SendableGift.fromJson(Map<String, dynamic>.from(g)))
          .toList(),
      history: rawHistory
          .whereType<Map>()
          .map((g) => GiftHistoryItem.fromJson(Map<String, dynamic>.from(g)))
          .toList(),
    );
  }

  static const GiftsData fallback = GiftsData(
    stats: GiftStats(received: '23', sent: '15', pending: '3'),
    received: [
      ReceivedGift(
        id: 'gift-1',
        from: 'Alex Johnson',
        avatarUrl: 'assets/images/avatars/avatar-1.png',
        giftName: 'Energy Pack',
        icon: Icons.flash_on,
        color: Color(0xFF10B981),
        timeLabel: '2 hours ago',
        message: 'Good luck on your next quiz!',
        claimed: false,
      ),
      ReceivedGift(
        id: 'gift-2',
        from: 'Sarah Miller',
        avatarUrl: 'assets/images/avatars/avatar-2.png',
        giftName: '1000 Coins',
        icon: Icons.monetization_on,
        color: Color(0xFFF59E0B),
        timeLabel: '1 day ago',
        message: 'Thanks for helping me yesterday!',
        claimed: true,
      ),
      ReceivedGift(
        id: 'gift-3',
        from: 'Mike Chen',
        avatarUrl: 'assets/images/avatars/avatar-3.png',
        giftName: 'Extra Life',
        icon: Icons.favorite,
        color: Color(0xFFEF4444),
        timeLabel: '2 days ago',
        message: 'Hope this helps in your games!',
        claimed: false,
      ),
    ],
    available: [
      SendableGift(
        id: 'send-energy',
        name: 'Energy Pack',
        description: '5 Energy Refills',
        icon: Icons.flash_on,
        color: Color(0xFF10B981),
        cost: '50 Coins',
      ),
      SendableGift(
        id: 'send-coins',
        name: 'Coin Gift',
        description: '1000 Coins',
        icon: Icons.monetization_on,
        color: Color(0xFFF59E0B),
        cost: '100 Coins',
      ),
      SendableGift(
        id: 'send-life',
        name: 'Extra Life',
        description: '1 Life Refill',
        icon: Icons.favorite,
        color: Color(0xFFEF4444),
        cost: '25 Coins',
      ),
      SendableGift(
        id: 'send-powerup',
        name: 'Power-up Bundle',
        description: '3 Random Power-ups',
        icon: Icons.auto_fix_high,
        color: Color(0xFF8B5CF6),
        cost: '150 Coins',
      ),
    ],
    history: [
      GiftHistoryItem(
        id: 'hist-1',
        type: 'sent',
        to: 'Alex Johnson',
        from: 'You',
        giftName: 'Energy Pack',
        icon: Icons.flash_on,
        color: Color(0xFF10B981),
        timeLabel: '3 hours ago',
        status: 'Delivered',
      ),
      GiftHistoryItem(
        id: 'hist-2',
        type: 'received',
        from: 'Sarah Miller',
        to: 'You',
        giftName: '1000 Coins',
        icon: Icons.monetization_on,
        color: Color(0xFFF59E0B),
        timeLabel: '1 day ago',
        status: 'Claimed',
      ),
      GiftHistoryItem(
        id: 'hist-3',
        type: 'sent',
        to: 'Mike Chen',
        from: 'You',
        giftName: 'Extra Life',
        icon: Icons.favorite,
        color: Color(0xFFEF4444),
        timeLabel: '2 days ago',
        status: 'Pending',
      ),
    ],
  );
}
