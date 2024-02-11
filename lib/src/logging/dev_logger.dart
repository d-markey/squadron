import 'dart:developer' as dev;

import 'base_dev_logger.dart';

/// Simple logger based on `dart:dev` `log` function
class DevSquadronLogger extends BaseDevSquadronLogger {
  /// Log based on `dart:developer`
  @override
  void log(String message) => dev.log(message);
}
