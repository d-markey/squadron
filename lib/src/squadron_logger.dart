import 'dart:developer' as dev show log;

import 'squadron.dart';

/// Basic interface for logging
abstract class SquadronLogger {
  /// Gets the log level
  int get logLevel;

  /// Sets the log level
  set logLevel(int value);

  /// Logs a message at [SquadronLogLevel.FINEST] level
  void finest(dynamic message);

  /// Logs a message at [SquadronLogLevel.FINER] level
  void finer(dynamic message);

  /// Logs a message at [SquadronLogLevel.FINE] level
  void fine(dynamic message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  void config(dynamic message);

  /// Logs a message at [SquadronLogLevel.INFO] level
  void info(dynamic message);

  /// Logs a message at [SquadronLogLevel.WARNING] level
  void warning(dynamic message);

  /// Logs a message at [SquadronLogLevel.SEVERE] level
  void severe(dynamic message);

  /// Logs a message at [SquadronLogLevel.SHOUT] level
  void shout(dynamic message);
}

/// Base class for simple loggers
abstract class BaseSquadronLogger implements SquadronLogger {
  @override
  int logLevel = SquadronLogLevel.SEVERE;

  /// Base logging method. Implement this method to display the [message].
  /// The method is called if the log level is enabled and is provided with a formatted message such as `[timestamp] [log-level] [Squadron.id] text of the message`
  void log(String message);

  void _log(int level, dynamic message) {
    if (level >= logLevel) {
      if (message is Function) {
        message = message();
      }
      final header =
          '[${DateTime.now().toUtc().toIso8601String()}] [${SquadronLogLevel.getName(level)}] [${Squadron.id}]';
      Iterable<String> lines;
      if (message is Iterable) {
        lines = message
            .map((m) => m?.toString() ?? '')
            .expand((m) => m.toString().split('\n'))
            .where((m) => m.isNotEmpty);
      } else {
        lines = message?.toString().split('\n').where((m) => m.isNotEmpty) ??
            const [];
      }
      for (var line in lines) {
        log('$header $line');
      }
    }
  }

  @override
  void finest(dynamic message) => _log(SquadronLogLevel.FINEST, message);

  @override
  void finer(dynamic message) => _log(SquadronLogLevel.FINER, message);

  @override
  void fine(dynamic message) => _log(SquadronLogLevel.FINE, message);

  @override
  void config(dynamic message) => _log(SquadronLogLevel.CONFIG, message);

  @override
  void info(dynamic message) => _log(SquadronLogLevel.INFO, message);

  @override
  void warning(dynamic message) => _log(SquadronLogLevel.WARNING, message);

  @override
  void severe(dynamic message) => _log(SquadronLogLevel.SEVERE, message);

  @override
  void shout(dynamic message) => _log(SquadronLogLevel.SHOUT, message);
}

class DevSquadronLogger extends BaseSquadronLogger {
  @override

  /// Log based on `dart:developer`
  void log(dynamic message) => dev.log(message?.toString() ?? '');
}

class ConsoleSquadronLogger extends BaseSquadronLogger {
  /// Log to console
  @override
  void log(dynamic message) => print(message);
}

/// Log level constants, compatible with `package:logging`
class SquadronLogLevel {
  SquadronLogLevel._();

  /// Lowest log level
  // ignore: constant_identifier_names
  static const ALL = 0;

  /// Finest log level
  // ignore: constant_identifier_names
  static const FINEST = 300;

  /// Finer log level
  // ignore: constant_identifier_names
  static const FINER = 400;

  /// Fine log level
  // ignore: constant_identifier_names
  static const FINE = 500;

  /// Config log level
  // ignore: constant_identifier_names
  static const CONFIG = 700;

  /// Information log level
  // ignore: constant_identifier_names
  static const INFO = 800;

  /// Warning log level
  // ignore: constant_identifier_names
  static const WARNING = 900;

  /// Severe log level
  // ignore: constant_identifier_names
  static const SEVERE = 1000;

  /// Shout log level
  // ignore: constant_identifier_names
  static const SHOUT = 1200;

  /// No logging
  // ignore: constant_identifier_names
  static const OFF = 2000;

  /// Gets the log level name
  static String getName(int logLevel) {
    if (logLevel < FINEST) return 'ALL';
    if (logLevel < FINER) return 'FINEST';
    if (logLevel < FINE) return 'FINER';
    if (logLevel < CONFIG) return 'FINE';
    if (logLevel < INFO) return 'CONFIG';
    if (logLevel < WARNING) return 'INFO';
    if (logLevel < SEVERE) return 'WARNING';
    if (logLevel < SHOUT) return 'SEVERE';
    if (logLevel < OFF) return 'SHOUT';
    return 'OFF';
  }
}
