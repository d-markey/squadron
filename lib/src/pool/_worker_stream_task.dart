import 'dart:async';

import '../_impl/xplat/_forward_stream_controller.dart';
import '../exceptions/squadron_exception.dart';
import '../stats/perf_counter.dart';
import '../worker/worker.dart';
import '_worker_task.dart';
import 'stream_task.dart';

class WorkerStreamTask<T, W extends Worker> extends WorkerTask<T, W>
    implements StreamTask<T> {
  /// Creates a new [StreamTask].
  WorkerStreamTask(this._producer, PerfCounter? counter) : super(counter) {
    _controller = ForwardStreamController<T>(onListen: () async {
      try {
        throwIfCanceled();
        if (_controller.isClosed) return;
        final stream = await _streamer.future;
        if (_controller.isClosed) {
          // we might have a problem here: the controller is closed but the worker
          // has started streaming; cancel the operation
          stream.listen((_) {}).cancel();
        } else {
          _controller.attachSubscription(stream.listen(
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
  final _streamer = Completer<Stream<T>>();

  late final ForwardStreamController<T> _controller;

  @override
  Stream<T> get stream => _controller.stream;

  void _closeWithError(SquadronException ex) {
    _controller.addError(ex);
    _controller.close();
  }

  void _onData(T data) => _controller.add(data);

  void _onError(ex, st) => _controller.addError(SquadronException.from(ex, st));

  @override
  void cancel([String? message]) {
    super.cancel(message);
    _closeWithError(canceledException!);
  }

  @override
  Future<bool> execute(W worker) {
    try {
      throwIfCanceled();
      final stream = _producer(worker);
      _streamer.complete(stream);
      return _controller.done.then((_) => true);
    } catch (ex, st) {
      _closeWithError(SquadronException.from(ex, st));
      return Future.value(false);
    }
  }
}
