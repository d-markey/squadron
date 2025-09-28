import 'dart:async';

import '../_impl/xplat/_forward_stream_controller.dart';
import '../exceptions/squadron_exception.dart';
import '../stats/perf_counter.dart';
import '../worker/worker.dart';
import '_worker_task.dart';
import 'stream_task.dart';

final class WorkerStreamTask<T, W extends Worker> extends WorkerTask<T, W>
    implements StreamTask<T> {
  /// Creates a new [StreamTask].
  WorkerStreamTask(this._producer, PerfCounter? counter) : super(counter) {
    _controller = ForwardStreamController<T>(onListen: () async {
      try {
        final worker = await _worker.future;
        if (canceledException != null || worker == null) {
          // the task was canceled
          throw canceledException!;
        } else {
          // otherwise, forward data from the worker
          _controller.attachSubscription(_producer(worker).listen(
            _onData,
            onError: _onError,
            onDone: _controller.close,
            cancelOnError: false,
          ));
        }
      } catch (ex, st) {
        _closeWithError(SquadronException.from(ex, st));
      }
    });
  }

  final Stream<T> Function(W worker) _producer;
  final _worker = Completer<W?>();

  late final ForwardStreamController<T> _controller;

  @override
  Stream<T> get stream => _controller.stream;

  void _closeWithError(SquadronException ex) {
    _controller.addError(ex);
    _controller.close();
  }

  void _onData(T data) => _controller.add(data);

  void _onError(Object ex, [StackTrace? st]) =>
      _controller.addError(SquadronException.from(ex, st));

  @override
  void cancel([String? message]) {
    super.cancel(message);
    if (!_worker.isCompleted) {
      // task canceled before it got scheduled
      _worker.complete(null);
    }
    if (_controller.subscription != null) {
      // task canceled after a listener subscribed to the stream
      _closeWithError(canceledException!);
    }
  }

  @override
  Future<bool> execute(W worker) {
    if (canceledException == null) {
      // run with worker
      _worker.complete(worker);
    }
    return _controller.done
        .then((_) => canceledException == null)
        .catchError((_) => false);
  }
}
