import 'dart:async';

import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';

class ForwardStreamController<T> {
  ForwardStreamController(
      {void Function()? onListen, FutureOr<void> Function()? onCancel}) {
    _controller = StreamController(
      onListen: onListen,
      onPause: _pause,
      onResume: _resume,
      onCancel: onCancel,
    );
  }

  late final StreamController<T> _controller;

  Stream<T> get stream => _controller.stream;

  Future<void> get done => _controller.done;

  bool get isClosed => _controller.isClosed;

  StreamSubscription? _sub;

  StreamSubscription? get subscription => _sub;

  void add(T data) {
    if (!_controller.isClosed) _controller.add(data);
  }

  void addError(SquadronException ex) {
    if (!_controller.isClosed) _controller.addError(ex);
  }

  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    _controller.close();
  }

  int _pauses = 0;

  void _pause() {
    // per Dart documentation https://api.dart.dev/dart-async/StreamSubscription/pause.html
    // If the subscription is paused more than once, an equal number of resumes
    // must be performed to resume the stream
    _pauses++;
  }

  void _resume() {
    if (_pauses > 0) {
      // per Dart documentation https://api.dart.dev/dart-async/StreamSubscription/pause.html
      // If the subscription is paused more than once, an equal number of resumes
      // must be performed to resume the stream
      _pauses--;
    } else {
      // per Dart documentation https://api.dart.dev/dart-async/StreamSubscription/resume.html
      // It is safe to resume even when the subscription is not paused, and the
      // resume will have no effect.
    }
  }

  void attachSubscription(StreamSubscription sub) {
    if (_sub != null) {
      throw SquadronErrorExt.create(
          'Invalid state: a subscription is already attached');
    }
    _sub = sub;
    // pass pending pause events on to the subscription
    while (_pauses > 0) {
      _pauses--;
      sub.pause();
    }
    // have the subscription handle pause/resume events from now on
    _controller.onPause = sub.pause;
    _controller.onResume = sub.resume;
    // have the subscription handle the cancel event if the controller doesn't
    // handle it already
    _controller.onCancel ??= sub.cancel;
    _sub = sub;
  }
}
