import 'dart:async';
import 'dart:math';

import 'cancellation_token.dart';

class CancellableToken extends CancellationToken {
  CancellableToken([this.message]) : super(Random.secure().nextInt(1 << 32 - 1));

  @override
  bool get cancelled => _cancelled;
  bool _cancelled = false;

  @override
  final String? message;

  List<FutureOr Function()>? _listeners;

  @override
  void addListener(FutureOr Function() listener) {
    _listeners ??= <FutureOr Function()>[];
    _listeners!.add(listener);
  }

  @override
  void removeListener(FutureOr Function() listener) {
    _listeners?.remove(listener);
  }

  void cancel() {
    if (!_cancelled) {
      _cancelled = true;
      _notifyListeners();
    }
  }

  void _notifyListeners() => _listeners?.forEach(_safeInvoke);

  static void _safeInvoke(FutureOr Function() listener) {
    try {
      listener();
    } catch (e) {
      print('notification to listener $listener failed: $e');
    }
  }
}
