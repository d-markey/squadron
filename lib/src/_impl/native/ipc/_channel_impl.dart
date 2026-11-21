part of '_channel.dart';

class IpcChannel implements Channel {
  IpcChannel(StreamTransport transport, this._process, this.logger,
      this.exceptionManager)
      : _transport = transport,
        _multiplexer = ChannelMultiplexer(transport) {
    _subscription = _multiplexer.messages.listen(_handleMultiplexedMessage);
  }

  // ignore: unused_field
  final StreamTransport _transport;
  final Process _process;
  final ChannelMultiplexer _multiplexer;
  late final StreamSubscription<MultiplexedMessage> _subscription;

  int _nextChannelId = 1;
  final _pendingRequests = <int, Completer<WorkerResponse>>{};
  final _activeStreams = <int, StreamController<WorkerResponse>>{};

  @override
  final ExceptionManager exceptionManager;

  @override
  final Logger? logger;

  final _closed = Completer<void>();

  @override
  Future<void> get closed => _closed.future;

  @override
  PlatformChannel serialize() => throw UnsupportedError(
      'IPC channels cannot be serialized across isolates');

  @override
  Channel share() =>
      throw UnsupportedError('IPC channels sharing not supported yet');

  void _handleMultiplexedMessage(MultiplexedMessage msg) {
    if (msg.type == MessageType.response) {
      final completer = _pendingRequests.remove(msg.channelId);
      if (completer != null && !completer.isCompleted) {
        final resp = msg.payload is WorkerResponse
            ? msg.payload as WorkerResponse
            : WorkerResponse.from(msg.payload);
        completer.complete(resp);
      } else {
        final streamController = _activeStreams[msg.channelId];
        if (streamController != null && !streamController.isClosed) {
          final resp = msg.payload is WorkerResponse
              ? msg.payload as WorkerResponse
              : WorkerResponse.from(msg.payload);
          streamController.add(resp);
          if (resp.endOfStream) {
            streamController.close();
            _activeStreams.remove(msg.channelId);
          }
        }
      }
    } else if (msg.type == MessageType.controlSignal) {
      if (msg.controlSignal == ControlSignal.endOfStream) {
        final streamController = _activeStreams.remove(msg.channelId);
        streamController?.close();
      } else if (msg.controlSignal == ControlSignal.error) {
        final completer = _pendingRequests.remove(msg.channelId);
        final err = msg.payload is SquadronException
            ? msg.payload as SquadronException
            : WorkerException(msg.payload.toString(), null);
        completer?.completeError(err);
        final streamController = _activeStreams.remove(msg.channelId);
        streamController?.addError(err);
        streamController?.close();
      }
    }
  }

  void _postRequest(int channelId, WorkerRequest req) {
    if (_closed.isCompleted) {
      throw SquadronErrorImpl.create('Channel is closed');
    }
    try {
      req.cancelToken?.ensureStarted();
      _multiplexer.send(channelId, MessageType.request, payload: req);
    } catch (ex, st) {
      logger?.e(() => 'Failed to post request $req: $ex');
      throw SquadronErrorImpl.create('Failed to post request: $ex', st);
    }
  }

  @override
  Future<void> close() async {
    if (!_closed.isCompleted) {
      await _subscription.cancel();
      await _multiplexer.close();
      try {
        await _process.stdin.close();
      } catch (_) {}
      try {
        await _process.exitCode.timeout(const Duration(seconds: 30));
      } on TimeoutException {
        try {
          _process.kill();
        } catch (_) {}
      } catch (_) {}
      _closed.complete();
    }
  }

  @override
  void cancelStream(StreamId streamId) {
    _multiplexer.send(streamId.handle, MessageType.controlSignal,
        controlSignal: ControlSignal.cancellation);
  }

  @override
  void cancelToken(SquadronCancelationToken? token) {
    if (token != null) {
      _multiplexer.send(0, MessageType.controlSignal,
          controlSignal: ControlSignal.cancellation, payload: token.id);
    }
  }

  @override
  Future<dynamic> sendRequest(
    int command,
    List args, {
    SquadronCancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) async {
    final channelId = _nextChannelId++;
    final completer = Completer<WorkerResponse>();
    _pendingRequests[channelId] = completer;

    final req =
        WorkerRequest.userCommand(null, command, args, token, inspectResponse);
    _postRequest(channelId, req);

    final response = await completer.future;
    if (response.error != null) {
      throw response.error!;
    }
    return response.result;
  }

  @override
  Stream<dynamic> sendStreamingRequest(
    int command,
    List args, {
    SquadronCancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) {
    final channelId = _nextChannelId++;
    late final StreamController<WorkerResponse> controller;
    controller = StreamController<WorkerResponse>(onCancel: () {
      _activeStreams.remove(channelId);
      cancelStream(StreamId.from(channelId)!);
      controller.close();
    });
    _activeStreams[channelId] = controller;

    final req =
        WorkerRequest.userCommand(null, command, args, token, inspectResponse);
    _postRequest(channelId, req);

    return controller.stream.map((resp) {
      if (resp.error != null) throw resp.error!;
      return resp.result;
    });
  }
}
