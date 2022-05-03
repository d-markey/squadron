import 'dart:async';
import 'dart:developer' as dev show log;

import 'channel.dart';
import 'squadron.dart';

/// Basic interface for logging
abstract class SquadronLogger {
  /// Gets the log level
  int get logLevel;

  /// Sets the log level
  set logLevel(int value);

  /// Base logging method. Implement this method to display the [message].
  /// The method is called if the log level is enabled and is provided with a formatted message such as
  /// `[timestamp] [log-level] [Squadron.id] text of the message`
  FutureOr log(String message);

  /// Logs a message at [SquadronLogLevel.debug] level
  FutureOr debug(dynamic message);

  /// Logs a message at [SquadronLogLevel.finest] level
  FutureOr finest(dynamic message);

  /// Logs a message at [SquadronLogLevel.finer] level
  FutureOr finer(dynamic message);

  /// Logs a message at [SquadronLogLevel.fine] level
  FutureOr fine(dynamic message);

  /// Logs a message at [SquadronLogLevel.config] level
  FutureOr config(dynamic message);

  /// Logs a message at [SquadronLogLevel.info] level
  FutureOr info(dynamic message);

  /// Logs a message at [SquadronLogLevel.warning] level
  FutureOr warning(dynamic message);

  /// Logs a message at [SquadronLogLevel.severe] level
  FutureOr severe(dynamic message);

  /// Logs a message at [SquadronLogLevel.shout] level
  FutureOr shout(dynamic message);
}

/// Base class for simple loggers
abstract class BaseSquadronLogger implements SquadronLogger {
  @override
  int logLevel = Squadron.logLevel;

  FutureOr _log(int level, dynamic message) {
    if (level >= logLevel ||
        (level == SquadronLogLevel.debug && Squadron.debugMode)) {
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
  FutureOr debug(dynamic message) => _log(SquadronLogLevel.debug, message);

  @override
  FutureOr finest(dynamic message) => _log(SquadronLogLevel.finest, message);

  @override
  FutureOr finer(dynamic message) => _log(SquadronLogLevel.finer, message);

  @override
  FutureOr fine(dynamic message) => _log(SquadronLogLevel.fine, message);

  @override
  FutureOr config(dynamic message) => _log(SquadronLogLevel.config, message);

  @override
  FutureOr info(dynamic message) => _log(SquadronLogLevel.info, message);

  @override
  FutureOr warning(dynamic message) => _log(SquadronLogLevel.warning, message);

  @override
  FutureOr severe(dynamic message) => _log(SquadronLogLevel.severe, message);

  @override
  FutureOr shout(dynamic message) => _log(SquadronLogLevel.shout, message);
}

/// Simple logger based on `dart:dev` `log` function
class DevSquadronLogger extends BaseSquadronLogger {
  @override

  /// Log based on `dart:developer`
  void log(dynamic message) => dev.log(message?.toString() ?? '');
}

/// Simple console logger (`print` function)
class ConsoleSquadronLogger extends BaseSquadronLogger {
  /// Log to console
  @override
  void log(dynamic message) => print(message);
}

/// Logger for workers, forwarding log messages to parent
class ParentSquadronLogger extends BaseSquadronLogger {
  ParentSquadronLogger(this._parent);

  final WorkerChannel _parent;

  /// Log to parent
  @override
  void log(dynamic message) => _parent.log(message?.toString() ?? '');
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
    if (logLevel < finest) return 'ALL';
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
