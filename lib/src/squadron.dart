import 'dart:async';

import 'squadron_logger.dart';

/// Squadron "Singleton". The main application thread and each worker thread will have their own private
/// [Squadron] singleton.
class Squadron {
  Squadron._();

  static int _logLevel = SquadronLogLevel.off;

  /// Gets the log level. Propagates to workers with the value that was set at the time the worker
  /// was created. Changes to this property do not propagate to workers after they have started.
  static int get logLevel => logger?.logLevel ?? _logLevel;

  /// Sets the log level. Changes to this property do not propagate to workers after they have started.
  static set logLevel(int value) {
    logger?.logLevel = value;
    _logLevel = value;
  }

  static SquadronLogger? _logger;

  /// Gets the current logger, if set.
  static SquadronLogger? get logger => _logger;

  /// Sets the current [logger] and sets the logger's [SquadronLogger.logLevel] to [Squadron.logLevel].
  static set logger(SquadronLogger? logger) {
    final level = logLevel;
    _logger = logger;
    _logger?.logLevel = level;
  }

  static String? _id;

  /// Squadron instance id to track identity of threads/workers. Returns `<undefined>` if it has not been set
  /// yet.
  static String get id => _id ?? '<undefined>';

  /// Sets the Squadron instance id. Once set, the id cannot be modified.
  static setId(String? value) {
    if (_id == null && value != null) {
      value = value.trim();
      if (value.isNotEmpty) {
        _id ??= value;
      }
    }
  }

  /// Logs a message at [SquadronLogLevel.finest] level
  static FutureOr finest(dynamic message) => logger?.finest(message);

  /// Logs a message at [SquadronLogLevel.finer] level
  static FutureOr finer(dynamic message) => logger?.finer(message);

  /// Logs a message at [SquadronLogLevel.fine] level
  static FutureOr fine(dynamic message) => logger?.fine(message);

  /// Logs a message at [SquadronLogLevel.config] level
  static FutureOr config(dynamic message) => logger?.config(message);

  /// Logs a message at [SquadronLogLevel.info] level
  static FutureOr info(dynamic message) => logger?.info(message);

  /// Logs a message at [SquadronLogLevel.warning] level
  static FutureOr warning(dynamic message) => logger?.warning(message);

  /// Logs a message at [SquadronLogLevel.severe] level
  static FutureOr severe(dynamic message) => logger?.severe(message);

  /// Logs a message at [SquadronLogLevel.shout] level
  static FutureOr shout(dynamic message) => logger?.shout(message);
}
