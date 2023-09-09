import 'base_dev_logger.dart';

/// Simple console logger (`print` function)
class ConsoleSquadronLogger extends BaseDevSquadronLogger {
  /// Log to console
  @override
  void log(String message) => print(message);
}
