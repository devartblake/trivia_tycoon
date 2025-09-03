class QrSettingsModel {
  final int scanLimit;
  final bool autoLaunch;

  QrSettingsModel({required this.scanLimit, required this.autoLaunch});

  QrSettingsModel copyWith({int? scanLimit, bool? autoLaunch}) {
    return QrSettingsModel(
      scanLimit: scanLimit ?? this.scanLimit,
      autoLaunch: autoLaunch ?? this.autoLaunch,
    );
  }
}
