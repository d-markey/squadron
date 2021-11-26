import 'dart:math';

import 'cancellation_token.dart';

class CancellableToken extends CancellationToken {
  CancellableToken([this.message])
      : super(Random.secure().nextInt(1 << 32 - 1));

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

  void cancel() {
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
