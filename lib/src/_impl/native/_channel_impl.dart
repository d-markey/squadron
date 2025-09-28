part of '_channel.dart';

/// [Channel] implementation for the Native world.
final class _VmChannel implements Channel {
  _VmChannel._(this._sendPort, this.logger, this.exceptionManager);

  /// [SendPort] to communicate with the [Isolate] if the channel is owned by
  /// the worker owner. Otherwise, [SendPort] to return values to the client.
  final vm.SendPort _sendPort;

  PlatformThread? _thread;
  final _activeConnections = <ForwardStreamController<WorkerResponse>>[];

  @override
  final ExceptionManager exceptionManager;

  @override
  final Logger? logger;

  bool _closed = false;

  /// [Channel] serialization in Native world returns the [SendPort].
  @override
  PlatformChannel serialize() => _sendPort;

  /// [Channel] sharing in JavaScript world returns a [_VmForwardChannel].
  @override
  Channel share() => _VmForwardChannel._(
      _sendPort, vm.ReceivePort(), logger, exceptionManager);

  void _postRequest(WorkerRequest req, {bool force = false}) {
    if (_closed && !force) {
      throw SquadronErrorImpl.create('Channel is closed');
    }
    try {
      req.cancelToken?.ensureStarted();
      _sendPort.send(req.wrapInPlace());
    } catch (ex, st) {
      logger?.e(() => 'Failed to post request $req: $ex');
      throw SquadronErrorImpl.create('Failed to post request: $ex', st);
    }
  }

  /// Sends a termination [WorkerRequest] to the [vm.Isolate].
  @override
  FutureOr<void> close() {
    if (!_closed) {
      _postRequest(WorkerRequest.stop());
      _closed = true;
    }
  }

  /// Sends a close stream [WorkerRequest] to the [vm.Isolate].
  @override
  FutureOr<void> cancelStream(int streamId) {
    _postRequest(WorkerRequest.cancelStream(streamId), force: true);
  }

  /// Sends a cancel token [WorkerRequest] to the [vm.Isolate].
  @override
  FutureOr<void> cancelToken(SquadronCancelationToken? token) {
    if (token != null) {
      _postRequest(WorkerRequest.cancel(token), force: true);
    }
  }

  void _enter(ForwardStreamController<WorkerResponse> controller) {
    _activeConnections.add(controller);
  }

  void _leave(ForwardStreamController<WorkerResponse> controller) {
    _activeConnections.remove(controller);
    controller.close();
  }

  Stream<dynamic> _getResponseStream(
    vm.ReceivePort port,
    WorkerRequest req,
    void Function(WorkerRequest) post, {
    required bool streaming,
  }) {
    final command = req.command;

    // send the request, return a stream of responses
    Stream<WorkerResponse> $sendRequest() {
      late final ForwardStreamController<WorkerResponse> controller;

      void $forwardMessage(WorkerResponse msg) {
        if (!controller.isClosed) controller.add(msg);
      }

      void $forwardError(Object error, [StackTrace? st]) {
        if (!controller.isClosed) {
          controller.addError(SquadronException.from(error, st, command));
        }
      }

      void $done() {
        _leave(controller);
      }

      controller = ForwardStreamController(onListen: () {
        // do nothing if the controller is closed already
        if (controller.isClosed) return;

        // bind the controller
        controller.attachSubscription(port.cast<WorkerResponse>().listen(
              $forwardMessage,
              onError: $forwardError,
              onDone: $done,
              cancelOnError: false,
            ));

        // send the request
        try {
          _enter(controller);
          post(req);
        } catch (ex, st) {
          $forwardError(ex, st);
          _leave(controller);
        }
      }, onCancel: () {
        _leave(controller);
      });
      return controller.stream;
    }

    // return a stream of decoded responses
    final res = ResultStream(this, req, $sendRequest, streaming);
    res.done.whenComplete(() => port.close()).ignore();
    return res.stream;
  }

  /// creates a [ReceivePort] and a [WorkerRequest] and sends it to the
  /// [Isolate]. This method expects a single value from the [Isolate]
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

    final receiver = vm.ReceivePort();
    final req = WorkerRequest.userCommand(
        receiver.sendPort, command, args, token, inspectResponse);
    sub = _getResponseStream(receiver, req, _postRequest, streaming: false)
        .listen($success, onError: $fail, onDone: $done);
    return completer.future;
  }

  /// Creates a [ReceivePort] and a [WorkerRequest] and sends it to the
  /// [Isolate]. This method expects a stream of values from the [Isolate].
  /// The [Isolate] must send a [WorkerResponse.endOfStream] to close the
  /// [Stream].
  @override
  Stream<dynamic> sendStreamingRequest(
    int command,
    List args, {
    SquadronCancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) {
    final receiver = vm.ReceivePort();
    final req = WorkerRequest.userCommand(
        receiver.sendPort, command, args, token, inspectResponse);
    return _getResponseStream(receiver, req, _postRequest, streaming: true);
  }
}
