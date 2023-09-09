import '../squadron.dart';
import 'base_logger.dart';
import 'squadron_log_level.dart';

/// Base class for dev loggers.
abstract class BaseDevSquadronLogger extends BaseSquadronLogger {
  /// Formats the log [message] by splitting it into individual lines with a header
  /// including a timestamp, the worker id and the message's log [level].
  @override
  Iterable<String> format(int level, dynamic message) {
    final header =
        '[${DateTime.now().toUtc().toIso8601String()}] [${SquadronLogLevel.getName(level)}] [${Squadron.id}]';
    if (message is Iterable) {
      message = message
          .map((m) => m?.toString() ?? '')
          .expand((m) => m.toString().split('\n'));
    } else {
      message = message?.toString().split('\n') ?? const [];
    }
    return message.where((m) => m.isNotEmpty).map((line) => '$header $line');
  }
}
