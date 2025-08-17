import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';

FutureOr<T> run<T>(FutureOr<T> Function() task,
    [CancelationToken? cancelationToken]) {
  if (cancelationToken == null) {
    // not cancellable
    return task();
  }

  final completer = Completer<T>();

  void $success(T result) {
    if (!completer.isCompleted) {
      // resetting the cancelation token will ensure pending callbacks (eg.
      // unawaited futures) will run, even if the cancelation token gets
      // canceled after the computation ran to completion
      cancelationToken = null;
      completer.complete(result);
    }
  }

  void $failure(Object exception, [StackTrace? stackTrace]) {
    if (!completer.isCompleted) {
      completer.completeError(exception, stackTrace);
    }
  }

  // run the task in a cancelable zone
  runZonedGuarded<void>(
    () {
      cancelationToken?.throwIfCanceled();
      final ret = task();
      if (ret is T) {
        $success(ret);
      } else {
        ret.then($success, onError: $failure);
      }
    },
    (ex, st) {
      throw Error.throwWithStackTrace(ex, st);
    },
    zoneSpecification: ZoneSpecification(
      run: <R>(self, parent, zone, f) {
        final ex = cancelationToken?.exception;
        if (ex != null) {
          $failure(ex);
          return null as R;
        } else {
          return parent.run(zone, f);
        }
      },
      runUnary: <R, P>(self, parent, zone, f, x) {
        final ex = cancelationToken?.exception;
        if (ex != null) {
          $failure(ex);
          return null as R;
        } else {
          return parent.runUnary(zone, f, x);
        }
      },
      runBinary: <R, P1, P2>(self, parent, zone, f, x, y) {
        final ex = cancelationToken?.exception;
        if (ex != null) {
          $failure(ex);
          return null as R;
        } else {
          return parent.runBinary(zone, f, x, y);
        }
      },
      scheduleMicrotask: (self, parent, zone, f) {
        final ex = cancelationToken?.exception;
        if (ex != null) {
          $failure(ex);
        } else {
          parent.scheduleMicrotask(zone, f);
        }
      },
    ),
  );

  return completer.future;
}

Stream<T> stream<T>(Stream<T> Function() task,
    [CancelationToken? cancelationToken]) {
  if (cancelationToken == null) {
    // not cancellable
    return task();
  }

  StreamSubscription<T>? sub;
  late final StreamController<T> controller;

  Future<void> $close([Object? exception, StackTrace? stackTrace]) async {
    final cancel = sub?.cancel();
    if (exception != null && !controller.isClosed) {
      controller.addError(exception, stackTrace);
    }
    controller.close();
    await cancel;
  }

  bool $canceled() {
    final ex = cancelationToken.exception;
    if (ex != null) {
      $close(ex);
      return true;
    } else {
      return false;
    }
  }

  Future<void> $forward(T data) async {
    if (!$canceled()) {
      if (!controller.isClosed) {
        controller.add(data);
      }
      await Future.delayed(Duration.zero);
    }
  }

  Future<void> $forwardError(Object exception, [StackTrace? stackTrace]) async {
    if (!$canceled()) {
      if (exception is CanceledException) {
        $close(exception);
      } else if (!controller.isClosed) {
        controller.addError(exception, stackTrace);
      }
      await Future.delayed(Duration.zero);
    }
  }

  var pauses = 0;
  void $pause() {
    if (sub == null) {
      pauses += 1;
    } else {
      sub?.pause();
    }
  }

  void $resume() {
    if (sub == null) {
      if (pauses > 0) {
        pauses -= 1;
      }
    } else {
      sub?.resume();
    }
  }

  controller = StreamController(
    onListen: () async {
      if ($canceled() || controller.isClosed) return;
      sub = task().listen($forward, onError: $forwardError, onDone: $close);
    },
    onCancel: $close,
    onPause: $pause,
    onResume: $resume,
  );

  return controller.stream;
}
