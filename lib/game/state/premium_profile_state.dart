class PremiumStatus {
  final bool isPremium;
  final int discountPercent;
  final DateTime? expiryDate;

  PremiumStatus({
    required this.isPremium,
    required this.discountPercent,
    this.expiryDate,
  });
}
