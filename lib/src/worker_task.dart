import 'dart:async';
import 'dart:collection';

import 'package:squadron/src/worker_exception.dart';

import 'perf_counter.dart';
import 'worker.dart';

class WorkerTask<W extends Worker> extends LinkedListEntry<WorkerTask<W>> {
  WorkerTask._future(this._computer, this._completer, this._counter, this._onDone)
    : _submitted = DateTime.now().microsecondsSinceEpoch
    , _producer = null
    , _streamer = null;

  WorkerTask._stream(this._producer, this._streamer, this._counter, this._onDone)
    : _submitted = DateTime.now().microsecondsSinceEpoch
    , _computer = null
    , _completer = null;

  static WorkerTask<W> prepareFuture<T, W extends Worker>(Future<T> Function(W worker) closure, PerfCounter? counter, void Function()? onDone)
    => WorkerTask<W>._future(closure, Completer<T>(), counter, onDone);

  static WorkerTask<W> prepareStream<T, W extends Worker>(Stream<T> Function(W worker) closure, PerfCounter? counter, void Function()? onDone)
    => WorkerTask<W>._stream(closure, StreamController<T>(), counter, onDone);

  // ignore: unused_field
  final int _submitted;
  
  int? _executed;
  int? _finished;

  void run(W worker) {
    _executed = DateTime.now().microsecondsSinceEpoch;
    if (_computer != null && _completer != null) {
      _computer!(worker)
        .then((value) {
          _finished = DateTime.now().microsecondsSinceEpoch;
          _counter?.update(_finished! - _executed!);
          _completer!.complete(value);
          if (_onDone != null) {
            _onDone!();
          }
        })
        .onError((error, stackTrace) {
          _finished = DateTime.now().microsecondsSinceEpoch;
          _counter?.update(_finished! - _executed!);
          _completer!.completeError(error ?? Exception('Unknown error'), stackTrace);
          if (_onDone != null) {
            _onDone!();
          }
        });
      return;
    }

    if (_producer != null && _streamer != null) {
      _streamer!.addStream(_producer!(worker))
        .then((value) {
          _finished = DateTime.now().microsecondsSinceEpoch;
          _counter?.update(_finished! - _executed!);
          _streamer!.close();
          if (_onDone != null) {
            _onDone!();
          }
        });
      return;
    }

    throw WorkerException('The worker task state is invalid; cannot run.');
  }

  final PerfCounter? _counter;
  final void Function()? _onDone;

  final Future Function(W worker)? _computer;
  final Completer? _completer;
  Future get future => _completer!.future;

  final Stream Function(W worker)? _producer;
  final StreamController? _streamer;
  Stream get stream => _streamer!.stream;
}
