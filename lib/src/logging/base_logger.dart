import '../squadron.dart';
import 'squadron_log_level.dart';
import 'squadron_logger.dart';

/// Base class for simple loggers
abstract class BaseSquadronLogger implements SquadronLogger {
  @override
  int logLevel = Squadron.logLevel;

  /// Formats the log [message] by calling its `toString()` method.
  Iterable<String> format(int level, dynamic message) sync* {
    yield message.toString();
  }

  void _log(int level, dynamic message) {
    if (level >= logLevel ||
        (level == SquadronLogLevel.debug && Squadron.debugMode)) {
      if (message is Function) {
        message = message();
      }
      for (var line in format(level, message)) {
        log(line);
      }
    }
  }

  @override
  void debug(dynamic message) => _log(SquadronLogLevel.debug, message);

  @override
  void finest(dynamic message) => _log(SquadronLogLevel.finest, message);

  @override
  void finer(dynamic message) => _log(SquadronLogLevel.finer, message);

  @override
  void fine(dynamic message) => _log(SquadronLogLevel.fine, message);

  @override
  void config(dynamic message) => _log(SquadronLogLevel.config, message);

  @override
  void info(dynamic message) => _log(SquadronLogLevel.info, message);

  @override
  void warning(dynamic message) => _log(SquadronLogLevel.warning, message);

  @override
  void severe(dynamic message) => _log(SquadronLogLevel.severe, message);

  @override
  void shout(dynamic message) => _log(SquadronLogLevel.shout, message);
}
