class ReactorRewardLine {
  final String type;
  final String label;
  final int? amount;
  final String? iconUrl;

  const ReactorRewardLine({
    required this.type,
    required this.label,
    this.amount,
    this.iconUrl,
  });

  factory ReactorRewardLine.fromJson(Map<String, dynamic> json) {
    return ReactorRewardLine(
      type: json['type']?.toString() ?? 'coins',
      label: json['label']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt(),
      iconUrl: json['iconUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'label': label,
        if (amount != null) 'amount': amount,
        if (iconUrl != null) 'iconUrl': iconUrl,
      };
}
