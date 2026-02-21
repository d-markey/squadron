import 'dart:async';

extension HexExt on int {
  String get hex => '0x${toRadixString(16).padLeft(8, '0')}';
}

extension ControllerSafeExt<T> on StreamController<T> {
  void safeAdd(T data) {
    if (!isClosed) add(data);
  }

  void safeAddError(Object error, [StackTrace? stackTrace]) {
    if (!isClosed) addError(error, stackTrace);
  }
}

extension CompleterSafeExt<T> on Completer<T> {
  void safeComplete([FutureOr<T>? value]) {
    if (!isCompleted) complete(value);
  }

  void safeCompleteError(Object error, [StackTrace? stackTrace]) {
    if (!isCompleted) completeError(error, stackTrace);
  }
}
