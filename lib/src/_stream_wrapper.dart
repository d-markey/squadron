import 'dart:async';

import 'cancellation_token.dart';
import 'worker_response.dart';
import 'worker_service.dart';

class StreamWrapper<T> {
  StreamWrapper(
      this._postRequest, this._messages, SquadronCallback onDone, this._token) {
    _controller = StreamController<T>(
      onListen: _onListen,
      onPause: _onPause,
      onResume: _onResume,
      onCancel: _onCancel,
    );
    _controller.done.then((_) => onDone());
  }

  Stream<T> get stream => _controller.stream;

  final Stream<dynamic> _messages;
  final SquadronCallback _postRequest;
  final CancellationToken? _token;

  late final StreamController<T> _controller;
  int _paused = 0;

  final _buffer = <WorkerResponse>[];

  void _process(WorkerResponse res) {
    if (res.endOfStream) {
      _controller.close();
      return;
    }
    final error = res.error;
    if (error != null) {
      _controller.addError(error, error.stackTrace);
    } else {
      _controller.add(res.result);
    }
  }

  void _onListen() {
    _messages.listen(
      (message) {
        if (_controller.isClosed) return;
        final res = WorkerResponse.deserialize(message);
        if (_paused > 0) {
          _buffer.add(res);
        } else {
          _process(res);
        }
        final cancelException = _token?.exception;
        if (cancelException != null) {
          _controller.addError(cancelException, cancelException.stackTrace);
          _buffer.clear();
          _controller.close();
        }
      },
      cancelOnError: false,
    );
    _postRequest();
  }

  void _onCancel() {
    _buffer.clear();
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
