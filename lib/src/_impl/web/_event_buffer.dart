import 'dart:async';

class EventBuffer<T> {
  EventBuffer(this._processValue, this._processError);

  FutureOr<void> Function()? onDeactivate;

  final void Function(T) _processValue;
  final void Function(Object, StackTrace?) _processError;

  final _buffer = <void Function()>[];

  var _pauses = 0;

  bool get isActive => _pauses > 0;

  void activate() => _pauses++;

  void deactivate() {
    if (_pauses == 1) {
      for (var fn in _buffer) {
        fn.call();
      }
      _buffer.clear();
      onDeactivate?.call();
    }
    if (_pauses > 0) {
      _pauses--;
    }
  }

  void add(T value) => _buffer.add(() => _processValue(value));

  void addError(Object err, StackTrace? st) =>
      _buffer.add(() => _processError(err, st));
}
