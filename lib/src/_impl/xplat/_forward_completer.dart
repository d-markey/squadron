import 'dart:async';

import '../../exceptions/squadron_exception.dart';

class ForwardCompleter<T> {
  final _res = Completer<T>();

  Future<T> get future => _res.future;

  void success(T data) {
    if (!_res.isCompleted) _res.complete(data);
  }

  void failure(SquadronException ex) {
    if (!_res.isCompleted) _res.completeError(ex);
  }
}
