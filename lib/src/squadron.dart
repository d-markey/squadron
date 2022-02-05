import 'squadron_logger.dart';

/// Squadron "Singleton"
/// The main application thread and each worker thread will have their own private Squadron singleton
class Squadron {
  Squadron._();

  /// Gets the log level. Propagates to workers with the value that is/was set at the time the worker it created. Changes to this property do not propagate by default.
  static int get logLevel => logger?.logLevel ?? SquadronLogLevel.OFF;

  /// Sets the log level
  static set logLevel(int value) => logger?.logLevel = value;

  /// Custom logger. The object must implement a "log()" method
  /// following the definition from the loging package:
  /// void log(level, message, error, stackTrace, zone);
  static SquadronLogger? logger;

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
  static void finest(Object? message) => logger?.finest(message);

  /// Logs a message at [SquadronLogLevel.FINER] level
  static void finer(Object? message) => logger?.finer(message);

  /// Logs a message at [SquadronLogLevel.FINE] level
  static void fine(Object? message) => logger?.fine(message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  static void config(Object? message) => logger?.config(message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  static void info(Object? message) => logger?.info(message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  static void warning(Object? message) => logger?.warning(message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  static void severe(Object? message) => logger?.severe(message);

  /// Logs a message at [SquadronLogLevel.CONFIG] level
  static void shout(Object? message) => logger?.shout(message);
}
