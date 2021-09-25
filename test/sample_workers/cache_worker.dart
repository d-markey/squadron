import 'dart:isolate';

import 'package:squadron/squadron.dart';

abstract class Cache {
  Future<dynamic> get(dynamic key);
  Future<bool> containsKey(dynamic key);
  Future set(dynamic key, dynamic value);
}

class CacheClient implements Cache {
  CacheClient(this._remote);

  final SendPort _remote;

  @override
  Future<dynamic> get(dynamic key) {
    return WorkerRequest(CacheWorker._get, [ key ]).send(_remote);
  }

  @override
  Future<bool> containsKey(dynamic key) {
    return WorkerRequest(CacheWorker._contains, [ key ]).send<bool>(_remote);
  }

  @override
  Future set(dynamic key, dynamic value) {
    assert(value != null); // null means not in cache; cannot store null
    return WorkerRequest(CacheWorker._set, [ key, value ]).send(_remote);
  }
}

class CacheWorker extends Worker implements Cache {
  CacheWorker() : super(CacheWorker._main);

  @override
  final startArguments = List.empty();

  @override
  Future<dynamic> get(dynamic key) {
    return send(_get, [ key ]);
  }

  @override
  Future<bool> containsKey(dynamic key) {
    return send(_contains, [ key ]);
  }

  @override
  Future set(dynamic key, dynamic value) {
    assert(value != null); // null means not in cache; cannot store null
    return send(_set, [ key, value ]);
  }

  // private implementation, this is the thread's main program
  static const _get = 1;
  static const _contains = 2;
  static const _set = 3;

  static final _cache = <dynamic, dynamic>{};

  static void _main(List command) {
    final receiver = ReceivePort();
    WorkerRequest.fromMessage(command).connect(receiver);

    receiver.listen((command) {
      final req = WorkerRequest.fromMessage(command);
      if (req.command == null) {
        receiver.close();
        return;
      }
      switch (req.command) {
        case _get:
          req.reply(_cache[req.args[0]]);
          return;
        case _contains:
          req.reply(_cache.containsKey(req.args[0]));
          return;
        case _set:
          _cache[req.args[0]] = req.args[1];
          req.reply();
          return;
        default:
          req.exception(WorkerException('unknown message ${req.command}'), StackTrace.current);
          return;
      }
    });
  }
}
