import 'dart:async';

import '../cancellation_token.dart';
import '../channel.dart';
import '../worker_request.dart';
import '../worker_response.dart';
import '../worker_service.dart';

/// Wraps a stream of messages coming in from a worker in response to a streaming worker request.
class StreamWrapper<T> {
  /// Constructs a new stream wrapper on top of [messages] (stream of messages received from the worker). Streaming
  /// operations will be initiated by sending the [streamRequest] to the worker using [postMethod]. This will not be
  /// done before a listener is attached to this instance's [stream] property.
  StreamWrapper(WorkerRequest streamRequest,
      {required PostMethod postMethod,
      required Stream messages,
      required SquadronCallback onDone,
      CancellationToken? token,
      required bool inspectRequest})
      : _streamRequest = streamRequest,
        _postMethod = postMethod,
        _messages = messages,
        _token = token,
        _inspectRequest = inspectRequest {
    _controller = StreamController<T>(
      onListen: _onListen,
      onPause: _onPause,
      onResume: _onResume,
      onCancel: _onCancel,
    );
    _token?.addListener(_canceller);
    _controller.done.then((_) {
      _token?.removeListener(_canceller);
      onDone();
    });
  }

  /// The actual data stream from the worker.
  Stream<T> get stream => _controller.stream;

  final Stream<dynamic> _messages;
  final WorkerRequest _streamRequest;
  final PostMethod _postMethod;
  final CancellationToken? _token;
  final bool _inspectRequest;

  late final StreamController<T> _controller;
  int _paused = 0;

  void _canceller() => _postMethod(WorkerRequest.cancel(_token!), false);

  void _process(WorkerResponse res) {
    final error = res.error;
    if (error != null) {
      _controller.addError(error, error.stackTrace);
    } else {
      _controller.add(res.result);
    }
  }

  /// Buffered storing worker responses while the stream is paused.
  final _buffer = <WorkerResponse>[];

  /// Will eventually store the stream ID received from the worker. If the stream is cancelled on the client side,
  /// the stream ID will be sent to the worker so it has a chance to stop streaming from the worker service.
  final _streamId = Completer<int>();

  void _onListen() {
    _messages.listen(
      (message) {
        if (_controller.isClosed) return;
        final cancelException = _token?.exception;
        if (cancelException != null) {
          if (!_streamId.isCompleted) {
            _streamId.complete(-1);
          }
          _controller.addError(cancelException, cancelException.stackTrace);
          _buffer.clear();
          _controller.close();
          return;
        }
        final res = WorkerResponse.deserialize(message);
        if (res.endOfStream) {
          _controller.close();
          return;
        }
        if (!_streamId.isCompleted) {
          // The first message received from the worker contains the stream ID. If the stream is cancelled on the
          // client side, the stream from the worker context should also be cancelled by sending a
          // WorkerRequest.cancelStream with this stream id.
          _streamId.complete(res.result);
          return;
        }
        if (_paused > 0) {
          _buffer.add(res);
        } else {
          _process(res);
        }
      },
      cancelOnError: false,
    );
    // initiate streaming operations now!
    _postMethod(_streamRequest, _inspectRequest);
  }

  Future _onCancel() async {
    final streamId = await _streamId.future;
    // notify the worker that the streaming operation has been cancelled
    _postMethod(WorkerRequest.cancelStream(streamId), false);
    _buffer.clear();
    _controller.close();
  }

  void _onPause() {
    // per Dart documentation: https://api.dart.dev/dart-async/StreamSubscription/pause.html
    // If the subscription is paused more than once, an equal number of resumes must be performed to resume the
    // stream.
    _paused++;
  }

  void _onResume() {
    if (_paused == 0) {
      // per Dart documentation: https://api.dart.dev/dart-async/StreamSubscription/resume.html
      // It is safe to resume even when the subscription is not paused, and the resume will have no effect.
      return;
    }
    _paused--;
    if (_paused == 0) {
      // per Dart documentation: https://api.dart.dev/dart-async/StreamSubscription/resume.html
      // When all previously calls to pause have been matched by a calls to resume, [...] the stream subscription
      // may emit events again.
      for (var e in _buffer) {
        _process(e);
      }
      _buffer.clear();
    }
  }
}
