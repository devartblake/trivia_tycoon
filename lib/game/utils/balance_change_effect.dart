
import '../models/currency_type.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class BalanceChangeEffect {
  static void trigger(CurrencyType type) {
    // Placeholder for animation or sound effect logic
    LogManager.debug('Balance changed for: \$type');
    // You could use a service or event trigger here for UI-level reactions.
  }
}
