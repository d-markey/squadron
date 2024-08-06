import 'dart:async';

import '../../exceptions/squadron_error.dart';

class PauseHandler {
  /// Handle pause/resume events for [controller]. Pause/resume events are forwarded to
  /// [subscription] if available. If [subscription] is null, the [PauseHandler] maintains
  /// an internal counter for pause/resume events.
  PauseHandler(
    StreamController controller, [
    StreamSubscription? subscription,
  ]) : _controller = controller {
    _controller.onPause = subscription?.pause ?? _onPause;
    _controller.onResume = subscription?.resume ?? _onResume;
  }

  final StreamController _controller;
  int _pauses = 0;

  void _onPause() {
    // per Dart documentation: https://api.dart.dev/dart-async/StreamSubscription/pause.html
    // If the subscription is paused more than once, an equal number of resumes must be performed to resume the
    // stream.
    _pauses++;
  }

  void _onResume() {
    if (_pauses > 0) {
      // per Dart documentation: https://api.dart.dev/dart-async/StreamSubscription/pause.html
      // If the subscription is paused more than once, an equal number of resumes must be performed to resume the
      // stream.
      _pauses--;
    } else {
      // per Dart documentation: https://api.dart.dev/dart-async/StreamSubscription/resume.html
      // It is safe to resume even when the subscription is not paused, and the resume will have no effect.
    }
  }

  /// Have [subscription] handle pause/resume events from now on.
  void overrideWith(StreamSubscription subscription) {
    if (_controller.onPause != _onPause || _controller.onResume != _onResume) {
      throw SquadronErrorExt.create(
        'Pause events have already been overriden with a subscription.',
      );
    }
    _controller.onPause = subscription.pause;
    _controller.onResume = subscription.resume;
    // forward pending pauses to the subscription
    while (_pauses > 0) {
      _pauses--;
      subscription.pause();
    }
  }
}
