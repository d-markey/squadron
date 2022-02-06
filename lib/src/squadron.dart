import 'squadron_logger.dart';

/// Squadron "Singleton"
/// The main application thread and each worker thread will have their own private Squadron singleton
class Squadron {
  Squadron._();

  static int _logLevel = SquadronLogLevel.OFF;

  /// Gets the log level. Propagates to workers with the value that is/was set at the time the worker it created. Changes to this property do not propagate by default.
  static int get logLevel => logger?.logLevel ?? _logLevel;

  /// Sets the log level
  static set logLevel(int value) {
    logger?.logLevel = value;
    _logLevel = value;
  }

  static SquadronLogger? _logger;

  /// Gets the current logger, if set.
  static SquadronLogger? get logger => _logger;

  /// Sets the current logger
  static set logger(SquadronLogger? logger) {
    final level = logLevel;
    _logger = logger;
    _logger?.logLevel = level;
  }

  static String? _id;

  /// Squadron instance id to track identity of threads/workers
  /// Returns `<undefined>` if it has not been set yet
  static String get id => _id ?? '<undefined>';

  /// Sets the Squadron instance id.
  /// Once set, the id cannot be modified.
  static setId(String? value) {
    if (_id == null && value != null) {
      value = value.trim();
      if (value.isNotEmpty) {
        _id ??= value;
      }
    }
  }

  /// Logs a message at [SquadronLogLevel.FINEST] level
  static void finest(dynamic message) => logger?.finest(message);

  /// Logs a message at [SquadronLogLevel.FINER] level
  static void finer(dynamic message) => logger?.finer(message);

  /// Logs a message at [SquadronLogLevel.FINE] level
  static void fine(dynamic message) => logger?.fine(message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  static void config(dynamic message) => logger?.config(message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  static void info(dynamic message) => logger?.info(message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  static void warning(dynamic message) => logger?.warning(message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  static void severe(dynamic message) => logger?.severe(message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  static void shout(dynamic message) => logger?.shout(message);
}
