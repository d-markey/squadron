import 'dart:math';

import 'package:squadron/squadron.dart';

import 'cancellation_token.dart';

enum CompositeMode { all, any }

enum CompositeReason { none, cancelled, timeout }

class CompositeToken extends CancellationToken {
  CompositeToken(Iterable<CancellationToken> tokens, this.mode, [this.message])
      : assert(tokens.isNotEmpty),
        _tokens = tokens.toList(),
        super(Random.secure().nextInt(1 << 32 - 1)) {
    _signaled == 0;
    _tokens.forEach(_register);
  }

  @override
  bool get isTimeout => _tokens.whereType<TimeOutToken>().isNotEmpty;

  @override
  bool get cancelled => _cancelled;
  bool _cancelled = false;

  final CompositeMode mode;

  final List<CancellationToken> _tokens;
  int _signaled = 0;

  @override
  final String? message;

  @override
  void start({void Function()? onTimeout}) =>
      _tokens.forEach(_start(onTimeout));

  void Function(CancellationToken token) _start(void Function()? onTimeout) =>
      (CancellationToken token) => token.start(onTimeout: onTimeout);

  @override
  void stop() => _tokens.forEach(_stop);

  void _stop(CancellationToken token) => token.stop();

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

  void _register(CancellationToken token) => token.addListener(_signal);

  void _unregister(CancellationToken token) => token.removeListener(_signal);

  void _signal() {
    _signaled++;
    if (_cancelled == false) {
      if (mode == CompositeMode.any ||
          (mode == CompositeMode.all && _signaled == _tokens.length)) {
        _tokens.forEach(_unregister);
        _cancelled = true;
        _notifyListeners();
      }
    }
  }

  void _notifyListeners() => _listeners?.forEach(_safeInvoke);

  static void _safeInvoke(void Function() listener) {
    try {
      listener();
    } catch (e) {
      print('notification to listener $listener failed: $e');
    }
  }
}
