import 'squadron_log_level.dart';

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
