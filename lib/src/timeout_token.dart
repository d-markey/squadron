import 'dart:async';
import 'dart:math';

import 'cancellation_token.dart';

class TimeOutToken extends CancellationToken {
  TimeOutToken(this.timeOut, [this.message])
      : super(Random.secure().nextInt(1 << 32 - 1));

  @override
  bool get isTimeout => true;

  final Duration? timeOut;

  @override
  bool get cancelled => _cancelled;
  bool _cancelled = false;

  @override
  final String? message;

  List<void Function()>? _listeners;

  @override
  void addListener(void Function() listener) {
    _listeners ??= <void Function()>[];
    _listeners!.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners?.remove(listener);
  }

  Timer? _timer;

  @override
  void start({void Function()? onTimeout}) {
    if (onTimeout != null) {
      if (_timer != null) {
        _timer!.cancel();
        _listeners!.removeAt(0);
      }
      _listeners!.insert(0, onTimeout);
      _timer ??= Timer(timeOut!, _cancel);
    }
  }

  @override
  void stop() {
    if (_timer != null) {
      _timer!.cancel();
      _listeners!.removeAt(0);
      _timer = null;
    }
  }

  void _cancel() {
    if (!_cancelled) {
      _cancelled = true;
      _notifyListeners();
    }
  }

  void _notifyListeners() => _listeners?.toList().forEach(_safeInvoke);

  static void _safeInvoke(void Function() listener) {
    try {
      listener();
    } catch (e) {
      print('notification to listener $listener failed: $e');
    }
  }
}
