/// Player/cohort-specific stock override.
/// Maps to POST /admin/store/overrides.
class StockOverrideFormModel {
  final String? playerId;
  final String sku;
  final int? overrideMaxQuantity;
  final DateTime? overrideExpiresAt;
  final bool grantFreeItem;
  final bool resetStockNow;
  final String? notes;
  final String? reasonCode;

  const StockOverrideFormModel({
    this.playerId,
    required this.sku,
    this.overrideMaxQuantity,
    this.overrideExpiresAt,
    this.grantFreeItem = false,
    this.resetStockNow = false,
    this.notes,
    this.reasonCode,
  });

  StockOverrideFormModel copyWith({
    String? playerId,
    String? sku,
    int? overrideMaxQuantity,
    DateTime? overrideExpiresAt,
    bool? grantFreeItem,
    bool? resetStockNow,
    String? notes,
    String? reasonCode,
    bool clearQuantity = false,
    bool clearExpiry = false,
  }) {
    return StockOverrideFormModel(
      playerId: playerId ?? this.playerId,
      sku: sku ?? this.sku,
      overrideMaxQuantity:
          clearQuantity ? null : (overrideMaxQuantity ?? this.overrideMaxQuantity),
      overrideExpiresAt:
          clearExpiry ? null : (overrideExpiresAt ?? this.overrideExpiresAt),
      grantFreeItem: grantFreeItem ?? this.grantFreeItem,
      resetStockNow: resetStockNow ?? this.resetStockNow,
      notes: notes ?? this.notes,
      reasonCode: reasonCode ?? this.reasonCode,
    );
  }

  Map<String, dynamic> toJson() => {
        if (playerId != null) 'playerId': playerId,
        'sku': sku,
        if (overrideMaxQuantity != null) 'overrideMaxQuantity': overrideMaxQuantity,
        if (overrideExpiresAt != null)
          'overrideExpiresAt': overrideExpiresAt!.toUtc().toIso8601String(),
        'grantFreeItem': grantFreeItem,
        'resetStockNow': resetStockNow,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (reasonCode != null) 'reasonCode': reasonCode,
      };
}

/// Flash sale definition.
/// Maps to POST/PUT /admin/store/flash-sales.
class FlashSaleFormModel {
  final String? saleId;
  final String title;
  final String linkedSku;
  final DateTime startTime;
  final DateTime endTime;
  final int purchaseCapPerUser;
  final double? discountPercent;
  final int? discountAmount;
  final String? eligibleCohort;
  final bool isActive;

  const FlashSaleFormModel({
    this.saleId,
    required this.title,
    required this.linkedSku,
    required this.startTime,
    required this.endTime,
    this.purchaseCapPerUser = 1,
    this.discountPercent,
    this.discountAmount,
    this.eligibleCohort,
    this.isActive = true,
  });

  FlashSaleFormModel copyWith({
    String? saleId,
    String? title,
    String? linkedSku,
    DateTime? startTime,
    DateTime? endTime,
    int? purchaseCapPerUser,
    double? discountPercent,
    int? discountAmount,
    String? eligibleCohort,
    bool? isActive,
    bool clearDiscountPercent = false,
    bool clearDiscountAmount = false,
    bool clearCohort = false,
  }) {
    return FlashSaleFormModel(
      saleId: saleId ?? this.saleId,
      title: title ?? this.title,
      linkedSku: linkedSku ?? this.linkedSku,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      purchaseCapPerUser: purchaseCapPerUser ?? this.purchaseCapPerUser,
      discountPercent: clearDiscountPercent ? null : (discountPercent ?? this.discountPercent),
      discountAmount: clearDiscountAmount ? null : (discountAmount ?? this.discountAmount),
      eligibleCohort: clearCohort ? null : (eligibleCohort ?? this.eligibleCohort),
      isActive: isActive ?? this.isActive,
    );
  }

  factory FlashSaleFormModel.fromJson(Map<String, dynamic> json) {
    // Backend (handoff 2026-04-26) uses startsAtUtc/endsAtUtc; legacy uses startTime/endTime.
    final startRaw = json['startsAtUtc']?.toString() ?? json['startTime']?.toString();
    final endRaw = json['endsAtUtc']?.toString() ?? json['endTime']?.toString();
    final now = DateTime.now().toUtc();
    return FlashSaleFormModel(
      saleId: json['id']?.toString() ?? json['saleId']?.toString(),
      title: (json['title'] ?? json['reason'] ?? json['sku'] ?? '').toString(),
      linkedSku: (json['sku'] ?? json['linkedSku'] ?? '').toString(),
      startTime: startRaw != null ? DateTime.parse(startRaw) : now,
      endTime: endRaw != null ? DateTime.parse(endRaw) : now.add(const Duration(days: 1)),
      purchaseCapPerUser: (json['purchaseCapPerUser'] as num?)?.toInt() ?? 1,
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toInt(),
      eligibleCohort: json['eligibleCohort']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (saleId != null) 'saleId': saleId,
        'title': title,
        'linkedSku': linkedSku,
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
        'purchaseCapPerUser': purchaseCapPerUser,
        if (discountPercent != null) 'discountPercent': discountPercent,
        if (discountAmount != null) 'discountAmount': discountAmount,
        if (eligibleCohort != null) 'eligibleCohort': eligibleCohort,
        'isActive': isActive,
      };

  bool get hasConflict => endTime.isBefore(startTime);
}
