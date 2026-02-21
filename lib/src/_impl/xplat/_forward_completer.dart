import 'dart:async';

import '../../exceptions/squadron_exception.dart';
import '../../utils.dart';

class ForwardCompleter<T> {
  final _res = Completer<T>();

  Future<T> get future => _res.future;

  void success(T data) => _res.safeComplete(data);

  void failure(SquadronException ex) => _res.safeCompleteError(ex);
}
