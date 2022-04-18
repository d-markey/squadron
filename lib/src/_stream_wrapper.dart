import 'dart:async';

import 'cancellation_token.dart';
import 'worker_request.dart';
import 'worker_response.dart';
import 'worker_service.dart';

class StreamWrapper<T> {
  StreamWrapper(this._streamRequest, this._post, this._messages,
      SquadronCallback onDone, this._token) {
    _controller = StreamController<T>(
      onListen: _onListen,
      onPause: _onPause,
      onResume: _onResume,
      onCancel: _onCancel,
    );
    _token?.addListener(_cancelToken);
    _controller.done.then((_) {
      _token?.removeListener(_cancelToken);
      onDone();
    });
  }

  Stream<T> get stream => _controller.stream;

  final Stream<dynamic> _messages;
  final WorkerRequest _streamRequest;
  final void Function(WorkerRequest req) _post;
  final CancellationToken? _token;

  late final StreamController<T> _controller;
  int _paused = 0;

  final _buffer = <WorkerResponse>[];

  void _cancelToken() {
    _post(WorkerRequest.cancel(_token!));
  }

  void _process(WorkerResponse res) {
    final error = res.error;
    if (error != null) {
      _controller.addError(error, error.stackTrace);
    } else {
      _controller.add(res.result);
    }
  }

  final _streamId = Completer<int>();

  int i = 0;

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
          // The first message contains the stream id. If the stream is cancelled on the client side, the stream
          // from the worker context should also be cancelled by sending a WorkerRequest.cancelStream with this
          // stream id.
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
    _post(_streamRequest);
  }

  Future _onCancel() async {
    final streamId = await _streamId.future;
    _post(WorkerRequest.cancelStream(streamId));
    _buffer.clear();
    _controller.close();
  }

  void _onPause() {
    _paused++;
  }

  void _onResume() {
    _paused--;
    if (_paused == 0 && _buffer.isNotEmpty) {
      for (var e in _buffer) {
        _process(e);
      }
      _buffer.clear();
    }
  }
}
