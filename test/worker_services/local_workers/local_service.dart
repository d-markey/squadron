import 'dart:async';

import 'package:squadron/squadron.dart';

abstract class LocalService implements WorkerService {
  FutureOr<String> getId();
  FutureOr<bool> throwException();
  Stream<int> sequence(int count);

  static const getIdCommand = 1;
  static const throwExceptionCommand = 2;
  static const sequenceCommand = 3;
}

class LocalServiceImpl extends LocalService {
  LocalServiceImpl(this._idGetter);

  final String Function() _idGetter;

  @override
  String getId() => _idGetter();

  @override
  bool throwException() => throw Exception('Intentional exception');

  @override
  Stream<int> sequence(int count) =>
      Stream.fromIterable(Iterable.generate(count));

  @override
  late final Map<int, CommandHandler> operations = {
    LocalService.getIdCommand: (req) => getId(),
    LocalService.throwExceptionCommand: (req) => throwException(),
    LocalService.sequenceCommand: (req) => sequence(req.args[0]),
  };
}
