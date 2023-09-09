import '../squadron.dart';
import 'base_dev_logger.dart';

/// Logger for workers, forwarding log messages to parent
class ParentSquadronLogger extends BaseDevSquadronLogger {
  ParentSquadronLogger();

  /// Log to parent
  @override
  void log(String message) => Squadron.parentChannel?.log(message);
}
