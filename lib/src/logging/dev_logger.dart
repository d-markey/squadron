import 'dart:developer' as dev;

import 'base_dev_logger.dart';

/// Simple logger based on `dart:dev` `log` function
class DevSquadronLogger extends BaseDevSquadronLogger {
  @override

  /// Log based on `dart:developer`
  void log(String message) => dev.log(message);
}
