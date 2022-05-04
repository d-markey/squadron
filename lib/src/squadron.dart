import 'channel.dart';
import 'squadron_logger.dart';

/// Squadron "Singleton". The main application thread and each worker thread will have their own private
/// [Squadron] singleton.
class Squadron {
  Squadron._();

  static int _logLevel = SquadronLogLevel.off;

  /// Gets the [logLevel]. Propagates to workers with the value that was set at the time the worker
  /// was created. Changes to this property do not propagate to workers after they have started.
  static int get logLevel => _logger?.logLevel ?? _logLevel;

  /// Sets the [logLevel]. Changes to this property do not propagate to workers after they have started.
  static set logLevel(int value) {
    _logger?.logLevel = value;
    _logLevel = value;
  }

  static final List<int> _logLevels = [];

  /// Remembers the current [logLevel], then setting it to [value] if not null. See [popLogLevel].
  static void pushLogLevel([int? value]) {
    _logLevels.add(Squadron.logLevel);
    if (value != null) {
      Squadron.logLevel = value;
    }
  }

  /// Restores the [logLevel] to the value it had before the last call to [pushLogLevel]. If [pushLogLevel]
  /// was never called, this method has no effect.
  static void popLogLevel() {
    if (_logLevels.isNotEmpty) {
      Squadron.logLevel = _logLevels.removeAt(0);
    }
  }

  static SquadronLogger? _logger;

  /// Sets the current [logger] and sets the logger's [SquadronLogger.logLevel] to [Squadron.logLevel].
  static void setLogger(SquadronLogger? logger) {
    final level = logLevel;
    _logger = logger;
    _logger?.logLevel = level;
  }

  /// Flag indicating whether Squadron runs in debug mode. When running in debug mode.
  static bool debugMode = false;

  static String? _id;

  /// Squadron instance id to track identity of threads/workers. Returns `<undefined>` if it has not been set
  /// yet.
  static String get id => _id ?? '<undefined>';

  /// Sets the Squadron instance id. Once set, the `id` cannot be modified.
  static setId(String value) {
    if (_id == null) {
      value = value.trim();
      if (value.isNotEmpty) {
        _id ??= value;
      }
    }
  }

  /// `WorkerChannel` to communicate with the parent. In the main thread, this will be `null`.
  static WorkerChannel? get parentChannel => _parentChannel;
  static WorkerChannel? _parentChannel;

  /// Sets the `WorkerChannel` to communicate with the parent. Once set, the `parentChannel` cannot be modified.
  /// When setting the parent channel, this method also installs a logger to forward log messages to the parent.
  static setParent(WorkerChannel parentChannel) {
    if (_parentChannel == null) {
      _parentChannel ??= parentChannel;
      _logger = ParentSquadronLogger(parentChannel);
    }
  }

  /// Logs a message at [SquadronLogLevel.debug] level. If [Squadron.debugMode] is `true`, the message will be
  /// displayed regardless of [Squadron.logLevel]. If `false`, [Squadron.logLevel] must be set to
  /// [SquadronLogLevel.all].
  static void debug(dynamic message) => _logger?.debug(message);

  /// Logs a message at [SquadronLogLevel.finest] level
  static void finest(dynamic message) => _logger?.finest(message);

  /// Logs a message at [SquadronLogLevel.finer] level
  static void finer(dynamic message) => _logger?.finer(message);

  /// Logs a message at [SquadronLogLevel.fine] level
  static void fine(dynamic message) => _logger?.fine(message);

  /// Logs a message at [SquadronLogLevel.config] level
  static void config(dynamic message) => _logger?.config(message);

  /// Logs a message at [SquadronLogLevel.info] level
  static void info(dynamic message) => _logger?.info(message);

  /// Logs a message at [SquadronLogLevel.warning] level
  static void warning(dynamic message) => _logger?.warning(message);

  /// Logs a message at [SquadronLogLevel.severe] level
  static void severe(dynamic message) => _logger?.severe(message);

  /// Logs a message at [SquadronLogLevel.shout] level
  static void shout(dynamic message) => _logger?.shout(message);
}

// for internal use
SquadronLogger? getSquadronLogger() => Squadron._logger;

/// Logs a message
void squadronLog(String message) => Squadron._logger?.log(message);
