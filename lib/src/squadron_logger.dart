import 'dart:developer' as dev show log;

import 'squadron.dart';

/// Basic interface for logging
abstract class SquadronLogger {
  const SquadronLogger();

  /// Gets the log level
  int get logLevel;

  /// Sets the log level
  set logLevel(int value);

  /// Base logging method. Implement this method to display the [message].
  /// The method is called if the log level is enabled.
  void log(String message);

  /// Logs a message at [SquadronLogLevel.debug] level
  void debug(dynamic message);

  /// Logs a message at [SquadronLogLevel.finest] level
  void finest(dynamic message);

  /// Logs a message at [SquadronLogLevel.finer] level
  void finer(dynamic message);

  /// Logs a message at [SquadronLogLevel.fine] level
  void fine(dynamic message);

  /// Logs a message at [SquadronLogLevel.config] level
  void config(dynamic message);

  /// Logs a message at [SquadronLogLevel.info] level
  void info(dynamic message);

  /// Logs a message at [SquadronLogLevel.warning] level
  void warning(dynamic message);

  /// Logs a message at [SquadronLogLevel.severe] level
  void severe(dynamic message);

  /// Logs a message at [SquadronLogLevel.shout] level
  void shout(dynamic message);
}

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

/// Simple logger based on `dart:dev` `log` function
class DevSquadronLogger extends BaseDevSquadronLogger {
  @override

  /// Log based on `dart:developer`
  void log(String message) => dev.log(message);
}

/// Simple console logger (`print` function)
class ConsoleSquadronLogger extends BaseDevSquadronLogger {
  /// Log to console
  @override
  void log(String message) => print(message);
}

/// Logger for workers, forwarding log messages to parent
class ParentSquadronLogger extends BaseDevSquadronLogger {
  ParentSquadronLogger();

  /// Log to parent
  @override
  void log(String message) => Squadron.parentChannel?.log(message);
}

/// Log level constants, compatible with `package:logging`
class SquadronLogLevel {
  SquadronLogLevel._();

  /// Lowest log level
  static const all = 0;

  /// Debug log level
  static const debug = 1;

  /// Finest log level
  static const finest = 300;

  /// Finer log level
  static const finer = 400;

  /// Fine log level
  static const fine = 500;

  /// Config log level
  static const config = 700;

  /// Information log level
  static const info = 800;

  /// Warning log level
  static const warning = 900;

  /// Severe log level
  static const severe = 1000;

  /// Shout log level
  static const shout = 1200;

  /// No logging
  static const off = 2000;

  /// Gets the log level name
  static String getName(int logLevel) {
    if (logLevel < debug) return 'ALL';
    if (logLevel < finest) return 'DEBUG';
    if (logLevel < finer) return 'FINEST';
    if (logLevel < fine) return 'FINER';
    if (logLevel < config) return 'FINE';
    if (logLevel < info) return 'CONFIG';
    if (logLevel < warning) return 'INFO';
    if (logLevel < severe) return 'WARNING';
    if (logLevel < shout) return 'SEVERE';
    if (logLevel < off) return 'SHOUT';
    return 'OFF';
  }
}
