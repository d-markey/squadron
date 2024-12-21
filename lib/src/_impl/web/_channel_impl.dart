part of '_channel.dart';

/// [Channel] implementation for the JavaScript world.
final class _WebChannel implements Channel {
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

  void _postRequest(WorkerRequest req, {bool force = false}) {
    if (_closed && !force) {
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
  FutureOr<void> close() {
    if (!_closed) {
      _postRequest(WorkerRequest.stop());
      _closed = true;
    }
  }

  /// Sends a close stream [WorkerRequest] to the [web.Worker].
  @override
  FutureOr<void> cancelStream(int streamId) {
    _postRequest(WorkerRequest.cancelStream(streamId), force: true);
  }

  /// Sends a cancel token [WorkerRequest] to the [web.Worker].
  @override
  FutureOr<void> cancelToken(SquadronCancelationToken? token) {
    if (token != null) {
      _postRequest(WorkerRequest.cancel(token), force: true);
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
      StreamController<WorkerResponse>? controller;

      void $forwardMessage(WorkerResponse msg) => controller?.add(msg);

      void $forwardError(Object error, StackTrace? st) =>
          controller?.addError(SquadronException.from(error, st, command));

      final buffer = EventBuffer($forwardMessage, $forwardError);

      Future<void> $close() async {
        com.port1.close();
        com.port2.close();
        final future = controller?.close();
        controller = null;
        await future;
      }

      controller = StreamController<WorkerResponse>(
        onListen: () {
          // do nothing if the controller is closed already
          if (controller == null) return;

          // bind the controller
          com.port1.onmessageerror = (web.ErrorEvent e) {
            final ex = SquadronException.from(getError(e), null, command);
            final handler = buffer.isActive ? buffer.addError : $forwardError;
            handler(ex, null);
          }.toJS;

          com.port1.onmessage = (web.MessageEvent e) {
            final res = WorkerResponseExt.from(getMessageEventData(e)!);
            final handler = buffer.isActive ? buffer.add : $forwardMessage;
            handler(res);
          }.toJS;

          // send the request
          try {
            post(req);
          } catch (ex, st) {
            if (buffer.isActive) {
              buffer.addError(ex, st);
              buffer.onDeactivate = $close;
            } else {
              $forwardError(ex, st);
              $close();
            }
          }
        },
        onPause: buffer.activate,
        onResume: buffer.deactivate,
        onCancel: $close,
      );

      return controller!.stream;
    }

    // return a stream of decoded responses
    final res = ResultStream(this, req, $sendRequest, streaming);
    res.done.whenComplete(() {
      // cleanup resources
      com.port1.close();
      com.port2.close();
    }).ignore();
    return res.stream;
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// single value from the [web.Worker].
  @override
  Future<dynamic> sendRequest(
    int command,
    List args, {
    SquadronCancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) {
    final completer = Completer();
    late final StreamSubscription sub;

    void $success(dynamic data) async {
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
        .listen($success, onError: $fail, onDone: $done);
    return completer.future;
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// stream of values from the [web.Worker]. The [web.Worker] must send a [WorkerResponse.endOfStream] to close
  /// the [Stream].
  @override
  Stream<dynamic> sendStreamingRequest(
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
    return _getResponseStream(com, req, post, streaming: true);
  }
}
