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

abstract class BaseSquadronLogger implements SquadronLogger {
  @override
  int logLevel = SquadronLogLevel.SEVERE;

  void log(int level, dynamic message);

  @override
  void finest(dynamic message) => log(SquadronLogLevel.FINEST, message);

  @override
  void finer(dynamic message) => log(SquadronLogLevel.FINER, message);

  @override
  void fine(dynamic message) => log(SquadronLogLevel.FINE, message);

  @override
  void config(dynamic message) => log(SquadronLogLevel.CONFIG, message);

  @override
  void info(dynamic message) => log(SquadronLogLevel.INFO, message);

  @override
  void warning(dynamic message) => log(SquadronLogLevel.WARNING, message);

  @override
  void severe(dynamic message) => log(SquadronLogLevel.SEVERE, message);

  @override
  void shout(dynamic message) => log(SquadronLogLevel.SHOUT, message);
}

class DevSquadronLogger extends BaseSquadronLogger {
  @override
  void log(int level, dynamic message) {
    if (level >= logLevel) {
      if (message is Function) {
        message = message();
      }
      dev.log('[${Squadron.id}] $message');
    }
  }
}

class ConsoleSquadronLogger extends BaseSquadronLogger {
  @override
  void log(int level, dynamic message) {
    if (level >= logLevel) {
      if (message is Function) {
        message = message();
      }
      print('[${Squadron.id}] $message');
    }
  }
}

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
}
