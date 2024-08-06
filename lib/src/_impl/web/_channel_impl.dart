part of '_channel.dart';

/// [Channel] implementation for the JavaScript world.
class _WebChannel implements Channel {
  _WebChannel._(this._sendPort, this._logger, this.exceptionManager);

  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is owned by the worker owner. Otherwise,
  /// [web.MessagePort] to return values to the client.
  final web.MessagePort _sendPort;
  final ExceptionManager exceptionManager;
  final Logger? _logger;

  bool _closed = false;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort].
  @override
  PlatformChannel serialize() => _sendPort;

  /// [Channel] sharing in JavaScript world returns a [_WebForwardChannel].
  @override
  Channel share() => _WebForwardChannel._(
      _sendPort, web.MessageChannel(), _logger, exceptionManager);

  void _postRequest(WorkerRequest req) {
    try {
      req.cancelToken?.ensureStarted();
      final data = req.wrapInPlace();
      final msg = data.jsify();
      final transfer = Transferables.get([req.channelInfo]);
      if (transfer == null || transfer.isEmpty) {
        _sendPort.postMessage(msg);
      } else {
        final jsTransfer = transfer.jsify() as JSArray;
        _sendPort.postMessage(msg, jsTransfer);
      }
    } catch (ex, st) {
      _logger?.e(() => 'Failed to post request $req: $ex');
      throw SquadronException.from('Failed to post request: $ex', st);
    }
  }

  void _inspectAndPostRequest(WorkerRequest req) {
    try {
      req.cancelToken?.ensureStarted();
      final data = req.wrapInPlace();
      final msg = data.jsify();
      final transfer = Transferables.get(data);
      if (transfer == null || transfer.isEmpty) {
        _sendPort.postMessage(msg);
      } else {
        final jsTransfer = transfer.jsify() as JSArray;
        _sendPort.postMessage(msg, jsTransfer);
      }
    } catch (ex, st) {
      _logger?.e(() => 'Failed to post request $req: $ex');
      throw SquadronException.from('Failed to post request: $ex', st);
    }
  }

  /// Sends a termination [WorkerRequest] to the [web.Worker] and clears the [web.MessagePort].
  @override
  FutureOr close() {
    if (!_closed) {
      _postRequest(WorkerRequest.stop());
      _closed = true;
    }
  }

  Stream<T> _buildResponseStream<T>(web.MessageChannel com,
      {required bool streaming}) {
    final cast = Cast.get<T>();
    late final StreamController<T> controller;

    final streamIdCompleter = Completer<int?>();
    if (!streaming) streamIdCompleter.complete(null);

    Future<void> close() async {
      print('CLOSE');
      com.port1.close();
      com.port2.close();
      await controller.close();
    }

    void onData(WorkerResponse res) {
      if (!res.unwrapInPlace(exceptionManager, _logger)) {
        print('DATA: $res --> nothing to do');
        return;
      }

      final error = res.error;
      if (error != null) {
        print('DATA: $res --> error $error');
        controller.addError(SquadronException.from(error));
      } else if (!streamIdCompleter.isCompleted) {
        // in streaming mode, the first response is the stream id
        print('DATA: $res --> streamId ${res.result}');
        streamIdCompleter.complete(Cast.toInt(res.result));
      } else if (streaming && res.endOfStream) {
        print('DATA: $res --> end of stream');
        if (!streamIdCompleter.isCompleted) {
          _logger?.e(() => 'Invalid state: null streamId');
          streamIdCompleter.complete(null);
        }
        close();
      } else {
        print('DATA: $res --> data ${res.result}');
        controller.add(cast(res.result));
      }
    }

    void onError(Object error, [StackTrace? stackTrace]) {
      print('ERROR: $error');
      controller.addError(SquadronException.from(error, stackTrace));
    }

    Future<void> onCancel() async {
      final streamId = await streamIdCompleter.future;
      if (streamId != null) {
        print('CANCEL STREAM $streamId');
        _postRequest(WorkerRequest.cancelStream(streamId));
      }
      print('CANCEL SUBSCRIPTION');
      await close();
    }

    controller = StreamController(
      onListen: () {
        com.port1.onmessageerror = (web.ErrorEvent e) {
          onError(getErrorEventError(e) ??
              SquadronException.from(getErrorEventMessage(e)));
        }.toJS;

        com.port1.onmessage = (web.MessageEvent e) {
          final msg = WorkerResponseExt.from(getMessageEventData(e) as List);
          print('ONMESSAGE $msg');
          onData(msg);
        }.toJS;
      },
      // TODO: pause/resume support
      onCancel: onCancel,
    );

    return controller.stream;
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// single value from the [web.Worker].
  @override
  Future<T> sendRequest<T>(
    int command,
    List args, {
    SquadronCancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }

    final com = web.MessageChannel();
    final req = WorkerRequest.userCommand(
        com.port2, command, args, token, inspectResponse);

    final stream = _buildResponseStream<T>(com, streaming: false);

    if (inspectRequest) {
      _inspectAndPostRequest(req);
    } else {
      _postRequest(req);
    }

    return stream.first;
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// stream of values from the [web.Worker]. The [web.Worker] must send a [WorkerResponse.endOfStream] to close
  /// the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(
    int command,
    List args, {
    SquadronCallback onDone = Channel.noop,
    SquadronCancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }

    final com = web.MessageChannel();
    final req = WorkerRequest.userCommand(
        com.port2, command, args, token, inspectResponse);

    final stream = _buildResponseStream<T>(com, streaming: true);

    if (inspectRequest) {
      _inspectAndPostRequest(req);
    } else {
      _postRequest(req);
    }

    return stream;
  }
}

/// [Channel] used to communicate between [web.Worker]s. Creates a
/// [web.MessageChannel] to receive commands on
/// [web.MessageChannel.port2] and forwards them to the worker's [web.MessagePort] via [web.MessageChannel.port1].
class _WebForwardChannel extends _WebChannel {
  /// [_remote] is the worker's [web.MessagePort], [_com] is the intermediate
  /// message channel
  _WebForwardChannel._(this._remote, this._com, Logger? logger,
      ExceptionManager exceptionManager)
      : super._(_com.port2, logger, exceptionManager) {
    _com.port1.onmessage = _forward.toJS;
  }

  /// [web.MessagePort] to the worker.
  final web.MessagePort _remote;

  /// [web.MessageChannel] used for forwarding messages.
  final web.MessageChannel _com;

  /// Forwards [web.MessageEvent.data] to the worker.
  void _forward(web.MessageEvent e) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }
    try {
      final data = getMessageEventData(e) as List;
      final transfer = Transferables.get(data);
      if (transfer == null || transfer.isEmpty) {
        _remote.postMessage(e.data);
      } else {
        final jsTransfer = transfer.jsify() as JSArray;
        _remote.postMessage(e.data, jsTransfer);
      }
    } catch (ex, st) {
      _logger?.e(() => 'Failed to post request $e: $ex');
      throw SquadronException.from('Failed to post request: $ex', st);
    }
  }

  /// Closes this [Channel], effectively stopping message forwarding.
  @override
  void close() {
    if (!_closed) {
      _com.port1.close();
      _closed = true;
    }
  }
}
