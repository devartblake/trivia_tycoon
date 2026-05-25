import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/native_platform_service.dart';

class NativeDialogs {
  static Future<String?> showInputDialog(String title, String message) async {
    try {
      return await NativePlatformService.instance.showInputDialog(
        title,
        message,
      );
    } catch (e) {
      LogManager.debug('Error showing input dialog: $e');
      return null;
    }
  }
}
