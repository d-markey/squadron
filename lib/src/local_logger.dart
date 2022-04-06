import 'dart:async';

import 'channel.dart';
import 'local_worker.dart';
import 'local_worker_client.dart';
import 'squadron.dart';
import 'squadron_logger.dart';
import 'worker_service.dart';

/// A [SquadronLogger] that also implements [WorkerService]. This logger wraps around a [BaseSquadronLogger]
/// responsible for actually logging messages. The point of this logger is to use it as a [LocalWorker] via
/// [LocalSquadronLogger.worker] so that workers can use a [LocalSquadronLoggerClient].
class LocalSquadronLogger implements SquadronLogger, WorkerService {
  LocalSquadronLogger(this.logger);

  final BaseSquadronLogger logger;

  late final LocalWorker<LocalSquadronLogger> worker = LocalWorker.create(this);

  List get connectionInfo => [worker.channel?.share().serialize(), logLevel];

  @override
  int get logLevel => logger.logLevel;

  @override
  set logLevel(int value) => logger.logLevel = value;

  FutureOr _log(int level, dynamic message) {
    dynamic id;
    if (message is _LogMessage) {
      id = message.id;
      message = message.msg;
    }
    id ??= Squadron.id;
    if (message is Function) {
      message = message();
    }
    if (level >= logLevel) {
      final header =
          '[${DateTime.now().toUtc().toIso8601String()}] [${SquadronLogLevel.getName(level)}] [$id]';
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
        logger.log('$header $line');
      }
    }
  }

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

  // use log levels as command IDs
  @override
  late final Map<int, CommandHandler> operations = {
    SquadronLogLevel.finest: (req) =>
        finest(_LogMessage.deserialize(req.args[0])),
    SquadronLogLevel.finer: (req) =>
        finer(_LogMessage.deserialize(req.args[0])),
    SquadronLogLevel.fine: (req) => fine(_LogMessage.deserialize(req.args[0])),
    SquadronLogLevel.config: (req) =>
        config(_LogMessage.deserialize(req.args[0])),
    SquadronLogLevel.info: (req) => info(_LogMessage.deserialize(req.args[0])),
    SquadronLogLevel.warning: (req) =>
        warning(_LogMessage.deserialize(req.args[0])),
    SquadronLogLevel.severe: (req) =>
        severe(_LogMessage.deserialize(req.args[0])),
    SquadronLogLevel.shout: (req) =>
        shout(_LogMessage.deserialize(req.args[0])),
  };
}

/// A [SquadronLogger] bound to a [LocalSquadronLogger]. Workers using this logger can have their log messages
/// sent to the [LocalSquadronLogger]. Usefull in Web scenarios where Web Workers typically log to the browser's
/// JavaScript console (as opposed to the main app which also logs messages via Dart's debugger).
class LocalSquadronLoggerClient extends LocalWorkerClient
    implements SquadronLogger {
  LocalSquadronLoggerClient._(Channel channel) : super(channel);

  static LocalSquadronLoggerClient? connect(dynamic connectionInfo) {
    if (connectionInfo is List) {
      final channel = Channel.deserialize(connectionInfo[0]);
      if (channel != null) {
        final loggerClient = LocalSquadronLoggerClient._(channel);
        loggerClient.logLevel = connectionInfo[1];
        return loggerClient;
      }
    }
    return null;
  }

  int _logLevel = Squadron.logLevel;

  @override
  int get logLevel => _logLevel;

  @override
  set logLevel(int value) {
    _logLevel = value;
  }

  FutureOr _log(int logLevel, dynamic message) {
    if (logLevel > _logLevel) {
      return send(logLevel, [_LogMessage(message).serialize()]);
    }
  }

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

class _LogMessage {
  _LogMessage._(this.id, this.msg);

  _LogMessage(dynamic msg) : this._(Squadron.id, msg);

  final String id;
  final dynamic msg;

  static const _$id = '\$';
  static const _$msg = '';

  Map serialize() {
    dynamic data = msg;
    if (data is Function) {
      data = msg();
    }
    return {_$id: Squadron.id, _$msg: data};
  }

  static _LogMessage? deserialize(Map message) =>
      (message[_$id] is String && message.containsKey(_$msg))
          ? _LogMessage._(message[_$id], message[_$msg])
          : null;
}
