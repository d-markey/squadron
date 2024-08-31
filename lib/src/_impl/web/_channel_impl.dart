part of '_channel.dart';

/// [Channel] implementation for the JavaScript world.
class _WebChannel implements Channel {
  _WebChannel._(this._sendPort, this.logger, this.exceptionManager);

  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is owned by the worker owner. Otherwise,
  /// [web.MessagePort] to return values to the client.
  final web.MessagePort _sendPort;

  @override
  final ExceptionManager exceptionManager;

  @override
  final Logger? logger;

  bool _closed = false;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort].
  @override
  PlatformChannel serialize() => _sendPort;

  /// [Channel] sharing in JavaScript world returns a [_WebForwardChannel].
  @override
  Channel share() => _WebForwardChannel._(
      _sendPort, web.MessageChannel(), logger, exceptionManager);

  void _postRequest(WorkerRequest req) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }
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
      logger?.e(() => 'Failed to post request $req: $ex');
      throw SquadronErrorExt.create('Failed to post request: $ex', st);
    }
  }

  void _inspectAndPostRequest(WorkerRequest req) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }
    req.cancelToken?.ensureStarted();
    req.cancelToken?.throwIfCanceled();
    try {
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
      logger?.e(() => 'Failed to post request $req: $ex');
      throw SquadronErrorExt.create('Failed to post request: $ex', st);
    }
  }

  /// Sends a termination [WorkerRequest] to the [web.Worker].
  @override
  FutureOr close() {
    if (!_closed) {
      _postRequest(WorkerRequest.stop());
      _closed = true;
    }
  }

  /// Sends a close stream [WorkerRequest] to the [web.Worker].
  @override
  FutureOr cancelStream(int streamId) {
    if (!_closed) {
      _postRequest(WorkerRequest.cancelStream(streamId));
    }
  }

  /// Sends a cancel token [WorkerRequest] to the [web.Worker].
  @override
  FutureOr cancelToken(SquadronCancelationToken? token) {
    if (token != null && !_closed) {
      _postRequest(WorkerRequest.cancel(token));
    }
  }

  Stream _getResponseStream(
    web.MessageChannel com,
    WorkerRequest req,
    void Function(WorkerRequest) post, {
    required bool streaming,
  }) {
    final command = req.command;

    // return a stream of responses
    Stream<WorkerResponse> $sendRequest() {
      late final StreamController<WorkerResponse> controller;

      void $forwardMessage(WorkerResponse msg) {
        if (!controller.isClosed) controller.add(msg);
      }

      void $forwardError(Object error, StackTrace? st) {
        if (!controller.isClosed) {
          controller.addError(SquadronException.from(error, st, command));
        }
      }

      void $processBufferedItem(BufferedItem<WorkerResponse> item) {
        if (item.item != null) {
          $forwardMessage(item.item!);
        } else {
          $forwardError(item.err!, item.st);
        }
      }

      final buffer = EventBuffer($processBufferedItem);

      Future<void> $close() async {
        com.port1.close();
        com.port2.close();
        if (!controller.isClosed) {
          controller.close();
        }
      }

      controller = StreamController(
        onListen: () {
          // do nothing if the controller is closed already
          if (controller.isClosed) return;

          // bind the controller
          com.port1.onmessageerror = (web.ErrorEvent e) {
            final ex = SquadronException.from(
              getErrorEventError(e) ??
                  getErrorEventMessage(e) ??
                  'Unknown error',
              null,
              command,
            );
            if (buffer.isActive) {
              buffer.addError(ex, null);
            } else {
              $forwardError(ex, null);
            }
          }.toJS;

          com.port1.onmessage = (web.MessageEvent e) {
            final res = WorkerResponseExt.from(getMessageEventData(e) as List);
            if (buffer.isActive) {
              buffer.add(res);
            } else {
              $forwardMessage(res);
            }
          }.toJS;

          // send the request
          try {
            post(req);
          } catch (ex, st) {
            if (buffer.isActive) {
              buffer.addError(ex, st);
              // TODO: since this instance is paused, the controller should probably
              // not be closed straight away
              $close();
            } else {
              $forwardError(ex, st);
              $close();
            }
          }
        },
        onPause: buffer.pause,
        onResume: buffer.resume,
        onCancel: $close,
      );

      return controller.stream;
    }

    // return a stream of decoded responses
    return ResultStream(this, req, $sendRequest, streaming).stream;
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
    final completer = Completer<T>();
    late final StreamSubscription<T> sub;

    void $success(T data) async {
      await sub.cancel();
      if (!completer.isCompleted) completer.complete(data);
    }

    void $fail(Object ex, [StackTrace? st]) async {
      await sub.cancel();
      if (!completer.isCompleted) completer.completeError(ex, st);
    }

    void $done() async {
      await sub.cancel();
      if (!completer.isCompleted) {
        $fail(WorkerException('No response from worker', null, command));
      }
    }

    final com = web.MessageChannel();
    final req = WorkerRequest.userCommand(
        com.port2, command, args, token, inspectResponse);
    final post = inspectRequest ? _inspectAndPostRequest : _postRequest;
    sub = _getResponseStream(com, req, post, streaming: false)
        .cast<
            T>() // TODO channel operations should return dynamic because T maybe a user-type (not transferable), or too complex (eg List<List>, Map<K, List>...)
        .listen($success, onError: $fail, onDone: $done);
    return completer.future;
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// stream of values from the [web.Worker]. The [web.Worker] must send a [WorkerResponse.endOfStream] to close
  /// the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(
    int command,
    List args, {
    SquadronCancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) {
    final com = web.MessageChannel();
    final req = WorkerRequest.userCommand(
        com.port2, command, args, token, inspectResponse);
    final post = inspectRequest ? _inspectAndPostRequest : _postRequest;
    return _getResponseStream(com, req, post, streaming: true).cast<
        T>(); // TODO channel operations should return dynamic because T maybe a user-type (not transferable), or too complex (eg List<List>, Map<K, List>...)
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
      logger?.e(() => 'Failed to post request $e: $ex');
      throw SquadronErrorExt.create('Failed to post request: $ex', st);
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
