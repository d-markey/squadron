import 'dart:async';

import 'perf_counter.dart';
import 'worker.dart';
import 'worker_exception.dart';

abstract class Task<T> {
  bool get isRunning;
  bool get isFinished;
  bool get isCancelled;

  Duration get waitTime;
  Duration get runningTime;

  void cancel();
}

abstract class ValueTask<T> extends Task<T> {
  Future<T> get value;
}

abstract class StreamTask<T> extends Task<T> {
  Stream<T> get stream;
}

class WorkerTask<T, W extends Worker> implements ValueTask<T>, StreamTask<T> {
  WorkerTask.value(this._computer, this._counter, this._onDone)
      : assert(_computer != null),
        _completer = Completer<T>(),
        _producer = null,
        _streamer = null {
    _submitted = _timeStamp();
  }

  WorkerTask.stream(this._producer, this._counter, this._onDone)
      : assert(_producer != null),
        _streamer = StreamController<T>(),
        _computer = null,
        _completer = null {
    _submitted = _timeStamp();
  }

  static int _timeStamp() => DateTime.now().microsecondsSinceEpoch;

  late final int _submitted;

  @override
  bool get isRunning =>
      _executed != null && _finished == null && _cancelled == null;
  int? _executed;

  @override
  bool get isFinished =>
      _executed != null && _finished != null && _cancelled == null;
  int? _finished;

  @override
  bool get isCancelled => _cancelled != null;
  int? _cancelled;

  @override
  Duration get waitTime => Duration(
      microseconds: (_executed ?? _cancelled ?? _timeStamp()) - _submitted);

  @override
  Duration get runningTime => _executed == null
      ? Duration.zero
      : Duration(
          microseconds: (_finished ?? _cancelled ?? _timeStamp()) - _executed!);

  @override
  void cancel() {
    if (_cancelled == null) {
      _cancelled = _timeStamp();
      if (_executed == null) {
        if (_completer != null) {
          _wrapUp(() => _completer!.completeError(CancelledException()),
              false);
        }
        if (_streamer != null) {
          _streamer!.addError(CancelledException());
          _wrapUp(() => _streamer!.close(), false);
        }
      }
    }
  }

  void _wrapUp(void Function() wrapper, bool success) async {
    _finished = _timeStamp();
    _counter?.update(_finished! - _executed!, success);
    wrapper();
    if (_onDone != null) {
      _onDone!();
    }
  }

  Future _runFuture(W worker, Future<T> Function(W worker) computer,
      Completer completer) async {
    if (completer.isCompleted) return completer.future;

    try {
      if (isCancelled) throw CancelledException();
      final value = await computer(worker);
      _wrapUp(() => completer.complete(value), true);
    } catch (ex, st) {
      _wrapUp(() => completer.completeError(ex, st), false);
    }
  }

  Future _runStream(W worker, Stream<T> Function(W worker) producer,
      StreamController streamer) async {
    if (streamer.isClosed) return Future.value();

    try {
      if (isCancelled) throw CancelledException();
      await for (var value in producer(worker)) {
        if (isCancelled) throw CancelledException();
        streamer.add(value);
      }
      _wrapUp(() => streamer.close(), true);
    } catch (ex, st) {
      streamer.addError(ex, st);
      _wrapUp(() => streamer.close(), false);
    }
  }

  Future run(W worker) {
    _executed = _timeStamp();
    if (_computer != null && _completer != null) {
      return _runFuture(worker, _computer!, _completer!);
    } else if (_producer != null && _streamer != null) {
      return _runStream(worker, _producer!, _streamer!);
    } else {
      return Future.error(
          WorkerException('The worker task state is invalid; cannot run.'));
    }
  }

  final PerfCounter? _counter;
  final void Function()? _onDone;

  final Future<T> Function(W worker)? _computer;
  final Completer<T>? _completer;

  @override
  Future<T> get value => _completer!.future;

  final Stream<T> Function(W worker)? _producer;
  final StreamController<T>? _streamer;

  @override
  Stream<T> get stream => _streamer!.stream;
}
