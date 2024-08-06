part of '_channel.dart';

/// [Channel] implementation for the Native world.
class _VmChannel implements Channel {
  _VmChannel._(this._sendPort, this._logger, this.exceptionManager);

  /// [SendPort] to communicate with the [Isolate] if the channel is owned by
  /// the worker owner. Otherwise, [SendPort] to return values to the client.
  final vm.SendPort _sendPort;

  final ExceptionManager exceptionManager;
  final Logger? _logger;

  bool _closed = false;

  /// [Channel] serialization in Native world returns the [SendPort].
  @override
  PlatformChannel serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    try {
      req.cancelToken?.ensureStarted();
      final data = req.wrapInPlace();
      _sendPort.send(data);
    } catch (ex, st) {
      _logger?.e(() => 'Failed to post request $req: $ex');
      throw SquadronException.from('Failed to post request: $ex', st);
    }
  }

  /// [Channel] sharing in Native world returns the same instance.
  @override
  Channel share() => this;

  /// Sends a termination [WorkerRequest] to the [Isolate] and clears the
  /// [SendPort].
  @override
  FutureOr close() {
    if (!_closed) {
      _postRequest(WorkerRequest.stop());
      _closed = true;
    }
  }

  Stream<T> _getStreamOfResponses<T>(vm.ReceivePort port,
      {required bool streaming}) {
    final cast = Cast.get<T>();
    late final StreamController<T> controller;
    late final PauseHandler pauseHandler;
    StreamSubscription<WorkerResponse>? sub;

    final streamIdCompleter = Completer<int?>();
    if (!streaming) streamIdCompleter.complete(null);

    Future<void> close() async {
      print('CLOSE');
      await sub?.cancel();
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
        sub = port.cast<WorkerResponse>().listen(
              onData,
              onError: onError,
              onDone: close,
              cancelOnError: false,
            );
        pauseHandler.overrideWith(sub!);
      },
      onCancel: onCancel,
    );
    pauseHandler = PauseHandler(controller);
    return controller.stream;
  }

  /// creates a [ReceivePort] and a [WorkerRequest] and sends it to the
  /// [Isolate]. This method expects a single value from the [Isolate]
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

    final receiver = vm.ReceivePort();
    final req = WorkerRequest.userCommand(
        receiver.sendPort, command, args, token, inspectResponse);

    final stream = _getStreamOfResponses<T>(receiver, streaming: false);

    _postRequest(req);
    return stream.first;
  }

  /// Creates a [ReceivePort] and a [WorkerRequest] and sends it to the
  /// [Isolate]. This method expects a stream of values from the [Isolate].
  /// The [Isolate] must send a [WorkerResponse.endOfStream] to close the
  /// [Stream].
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

    final receiver = vm.ReceivePort();
    final req = WorkerRequest.userCommand(
        receiver.sendPort, command, args, token, inspectResponse);

    final stream = _getStreamOfResponses<T>(receiver, streaming: true);

    _postRequest(req);
    return stream;
  }
}
