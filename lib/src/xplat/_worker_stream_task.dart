import 'dart:async';

import '../perf_counter.dart';
import '../squadron_error.dart';
import '../squadron_exception.dart';
import '../worker.dart';
import '../worker_task.dart';

import '_worker_task.dart';

class WorkerStreamTask<T, W extends Worker> extends WorkerTask<T, W>
    implements StreamTask<T> {
  /// Creates a new [StreamTask].
  WorkerStreamTask(this._producer, PerfCounter? counter) : super(counter) {
    _controller = StreamController<T>(
        onListen: _onListen,
        onPause: _onPause,
        onResume: _onResume,
        onCancel: _onCancel);
  }

  final Stream<T> Function(W worker) _producer;
  final _streamer = Completer<Stream<T>?>();
  late final StreamController<T> _controller;

  @override
  Stream<T> get stream => _controller.stream;

  int _paused = 0;
  bool _isPaused = false;
  StreamSubscription<T>? _subscription;

  void _onPause() {
    if (_paused == 0) {
      if (_subscription != null && !_isPaused) {
        _subscription!.pause();
        _isPaused = true;
      }
    }
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
      if (_subscription != null && _isPaused) {
        _subscription!.resume();
        _isPaused = false;
      }
    }
  }

  FutureOr _onCancel() => _subscription?.cancel(); /*_subscription?.cancel();*/

  void _close([SquadronException? exception]) {
    _subscription?.cancel();
    if (!_controller.isClosed) {
      if (exception != null) {
        _controller.addError(exception, exception.stackTrace);
      }
      _controller.close();
    }
  }

  void _done([SquadronException? exception]) =>
      wrapUp(() => _close(exception), (exception == null));

  @override
  void cancel([String? message]) {
    super.cancel(message);
    _done(cancelledException);
  }

  void _onError(ex, st) {
    _controller.addError(SquadronException.from(error: ex, stackTrace: st), st);
  }

  void _onData(T data) {
    if (isCancelled) {
      _done(cancelledException);
    } else {
      _controller.add(data);
    }
  }

  void _onListen() async {
    if (_controller.isClosed) {
      return _done();
    }
    if (isCancelled) {
      return _done(cancelledException);
    }
    try {
      final stream = await _streamer.future;
      if (stream == null) {
        _done(newSquadronError('null stream'));
      } else {
        _subscription = stream.listen(
          _onData,
          onError: _onError,
          onDone: _done,
        );
        if (_paused > 0 && !_isPaused) {
          _subscription!.pause();
          _isPaused = true;
        }
      }
    } catch (ex, st) {
      _done(SquadronException.from(error: ex, stackTrace: st));
    }
  }

  @override
  Future run(W worker) => super.run(worker).then((_) {
        _streamer.complete(_producer(worker));
        return _controller.done;
      });
}
