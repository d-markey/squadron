import 'dart:io';

import 'base_dev_logger.dart';

/// Simple native console logger (using `stdout` stream instead of `print`).
/// This logger should reduce the probability of having log messages displayed
/// on the same line.
class StdoutSquadronLogger extends BaseDevSquadronLogger {
  /// Log to console
  @override
  void log(String message) => stdout.write('message\n');
}
