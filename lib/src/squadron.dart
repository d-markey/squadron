import 'package:meta/meta.dart';

import 'exceptions/exception_manager.dart';
import 'logging/squadron_log_level.dart';
import 'logging/squadron_logger.dart';
import 'worker/worker_channel.dart';

/// Squadron singleton. The main application thread and each worker thread will have their own private
/// [Squadron] singleton.
class Squadron {
  Squadron._();

  static Squadron? _instance;

  static Squadron _getOrInitialize() {
    var sq = _instance;
    if (sq == null) {
      sq = Squadron._();
      sq._debugMode = __debugMode;
      _instance = sq;
    }
    return sq;
  }

  /// Whether the Squadron singleton is initialized or not. This property will be `true` if any of these
  /// has been called: [pushLogLevel], [setLogger], [setId], [setParent], or if [logLevel] has been set.
  /// The Squadron singleton may be reset by calling [shutdown].
  static bool get isInitialized => _instance != null;

  /// Resets the Squadron singleton. [isInitialized] will return `false` after this call, and a new
  /// Squadron singleton may be reinitialized.
  static void shutdown() {
    __debugMode = false;
    _instance = null;
  }

  final _exceptionManager = ExceptionManager();

  static ExceptionManager? get exceptionManager => _instance?._exceptionManager;

  SquadronLogger? _logger;

  /// Sets the current [logger] and sets the logger's [SquadronLogger.logLevel] to [Squadron.logLevel].
  static void setLogger(SquadronLogger? logger) {
    final sq = _getOrInitialize();
    final level = logLevel;
    sq._logger = logger;
    sq._logger?.logLevel = level;
  }

  int _logLevel = SquadronLogLevel.off;

  /// Gets the [logLevel]. Propagates to workers with the value that was set at the time the worker
  /// was created. Changes to this property do not propagate to workers after they have started.
  static int get logLevel =>
      _instance?._logger?.logLevel ??
      _instance?._logLevel ??
      SquadronLogLevel.off;

  /// Sets the [logLevel]. Changes to this property do not propagate to workers after they have started.
  static set logLevel(int value) {
    final sq = _getOrInitialize();
    sq._logger?.logLevel = value;
    sq._logLevel = value;
  }

  final _logLevels = <int>[];

  /// Remembers the current [logLevel], then setting it to [value] if not null. See [popLogLevel].
  static void pushLogLevel([int? value]) {
    final sq = _getOrInitialize();
    sq._logLevels.add(Squadron.logLevel);
    if (value != null) {
      Squadron.logLevel = value;
    }
  }

  /// Restores the [logLevel] to the value it had before the last call to [pushLogLevel]. If [pushLogLevel]
  /// was never called, this method has no effect and return `null`. Otherwise, it returns the value of
  /// [logLevel] after it has been restored.
  static int? popLogLevel() {
    final sq = _getOrInitialize();
    if (sq._logLevels.isNotEmpty) {
      Squadron.logLevel = sq._logLevels.removeLast();
    }
    return Squadron.logLevel;
  }

  /// Flag indicating whether Squadron runs in debug mode. When running in debug mode, messages logged at
  /// [SquadronLogLevel.debug] level will be logged regardless of the current [logLevel].
  static bool get debugMode => _instance?._debugMode ?? __debugMode;

  static set debugMode(bool value) {
    __debugMode = value;
    _instance?._debugMode = value;
  }

  static bool __debugMode = false;
  bool _debugMode = false;

  String? _id;

  /// Squadron instance id to track identity of threads/workers. Returns an empty String if the Squadron singleton
  /// has not been initialized yet, or if its `id` has not been set yet.
  static String? get id => _instance?._id;

  /// Sets the Squadron instance `id`. Once set, the [id] cannot be modified. The only way to assign a new `id`
  /// is to first call [shutdown], then initialize a new Squadron instance.
  static void setId(String value) {
    final sq = _getOrInitialize();
    if (sq._id == null) {
      value = value.trim();
      if (value.isNotEmpty) {
        sq._id ??= value;
      }
    }
  }

  /// `WorkerChannel` to communicate with the parent. In the main thread, this will be `null`.
  static WorkerChannel? get parentChannel => _instance?._parentChannel;
  WorkerChannel? _parentChannel;

  /// Sets the `WorkerChannel` to communicate with the parent. Once set, the `parentChannel` cannot be modified.
  /// When setting the parent channel, this method also installs a logger to forward log messages to the parent.
  static void setParent(WorkerChannel parentChannel) =>
      _getOrInitialize()._parentChannel ??= parentChannel;

  /// Logs a message at [SquadronLogLevel.debug] level. If [Squadron.debugMode] is `true`, the message will be
  /// displayed regardless of [Squadron.logLevel]. If `false`, the message will be logged if [Squadron.logLevel]
  /// is set to [SquadronLogLevel.all].
  static void debug(dynamic message) {
    final logger = _instance?._logger;
    if (logger != null) {
      logger.debug(message);
    } else if (debugMode) {
      if (message is Function) {
        message = message();
      }
      print('[DEBUG] $message');
    }
  }

  /// Logs a message at [SquadronLogLevel.finest] level
  static void finest(dynamic message) => _instance?._logger?.finest(message);

  /// Logs a message at [SquadronLogLevel.finer] level
  static void finer(dynamic message) => _instance?._logger?.finer(message);

  /// Logs a message at [SquadronLogLevel.fine] level
  static void fine(dynamic message) => _instance?._logger?.fine(message);

  /// Logs a message at [SquadronLogLevel.config] level
  static void config(dynamic message) => _instance?._logger?.config(message);

  /// Logs a message at [SquadronLogLevel.info] level
  static void info(dynamic message) => _instance?._logger?.info(message);

  /// Logs a message at [SquadronLogLevel.warning] level
  static void warning(dynamic message) => _instance?._logger?.warning(message);

  /// Logs a message at [SquadronLogLevel.severe] level
  static void severe(dynamic message) => _instance?._logger?.severe(message);

  /// Logs a message at [SquadronLogLevel.shout] level
  static void shout(dynamic message) => _instance?._logger?.shout(message);
}

@internal
extension LoggerExt on Squadron {
  static SquadronLogger? get logger => Squadron._instance?._logger;
}
