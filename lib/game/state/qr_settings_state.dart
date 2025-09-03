import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui_components/qr_code/models/qr_settings_model.dart';
import '../../core/services/settings/app_settings.dart';

class QrSettingsNotifier extends StateNotifier<QrSettingsModel> {
  QrSettingsNotifier() : super(QrSettingsModel(scanLimit: 50, autoLaunch: false)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final scanLimit = await AppSettings.getQrScanHistoryLimit();
    final autoLaunchEnabled = await AppSettings.getQrAutoLaunchEnabled();
    state = QrSettingsModel(scanLimit: scanLimit, autoLaunch: autoLaunchEnabled);
  }

  Future<void> updateScanLimit(int limit) async {
    await AppSettings.setQrScanHistoryLimit(limit);
    state = state.copyWith(scanLimit: limit);
  }

  Future<void> updateAutoLaunch(bool enabled) async {
    await AppSettings.setQrAutoLaunchEnabled(enabled);
    state = state.copyWith(autoLaunch: enabled);
  }
}
