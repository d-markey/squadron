import 'dart:async';
import 'dart:isolate';

import 'package:squadron/squadron.dart';

abstract class Cache {
  Future<dynamic> get(dynamic key);
  Future<bool> containsKey(dynamic key);
  Future set(dynamic key, dynamic value, {Duration? timeToLive});
}

class CacheClient implements Cache {
  CacheClient(this._remote);

  final SendPort _remote;

  @override
  Future<dynamic> get(dynamic key) {
    return WorkerRequest(CacheWorker._get, [key]).send(_remote);
  }

  @override
  Future<bool> containsKey(dynamic key) {
    return WorkerRequest(CacheWorker._contains, [key]).send<bool>(_remote);
  }

  @override
  Future set(dynamic key, dynamic value, {Duration? timeToLive}) {
    assert(value != null); // null means not in cache; cannot store null
    return WorkerRequest(
            CacheWorker._set, [key, value, timeToLive?.inMicroseconds])
        .send(_remote);
  }
}

class CacheWorker extends Worker implements Cache {
  CacheWorker() : super(CacheWorker._main);

  @override
  final startArguments = List.empty();

  @override
  Future<dynamic> get(dynamic key) {
    return send(_get, [key]);
  }

  @override
  Future<bool> containsKey(dynamic key) {
    return send(_contains, [key]);
  }

  @override
  Future set(dynamic key, dynamic value, {Duration? timeToLive}) {
    assert(value != null); // null means not in cache; cannot store null
    return send(_set, [key, value, timeToLive?.inMicroseconds]);
  }

  //////////////////////////////////////////////////////////////////////////////
  ////////////////////////                              ////////////////////////
  ////////////////////////    private implementation    ////////////////////////
  ////////////////////////                              ////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  // command dispatcher
  static final _operations = <int, FutureOr Function(WorkerRequest req)>{
    _get: _getImpl,
    _contains: _containsImpl,
    _set: _setImpl
  };

  static const _get = 1;
  static const _contains = 2;
  static const _set = 3;

  // worker main program
  static void _main(List command) {
    final receiver = ReceivePort();
    WorkerRequest.fromMessage(command).connect(receiver);

    receiver.listen((command) {
      WorkerRequest? req;
      try {
        req = WorkerRequest.fromMessage(command);
        if (req.command == null) {
          receiver.close();
          return;
        }
        final op = _operations[req.command];
        if (op != null) {
          req.reply(op(req));
        } else {
          req.exception(WorkerException('unknown message ${req.command}'),
              StackTrace.current);
        }
      } on WorkerException catch (e, st) {
        req?.exception(e, st);
      } catch (e, st) {
        req?.exception(
            WorkerException('unexpected exception: ${e.runtimeType} => $e}',
                stackTrace: st.toString()),
            st);
      }
    });
  }

  // cache implementation

  static final _cache = <dynamic, _CacheEntry>{};

  static dynamic _getImpl(WorkerRequest req) {
    final entry = _cache[req.args[0]];
    if (entry == null) {
      // not in cache
      return null;
    } else if (entry._expires == null ||
        entry._expires!.isBefore(DateTime.now())) {
      // in cache, still valid
      return entry._data;
    } else {
      // in cache, expired
      _cache.remove(req.args[0]);
      return null;
    }
  }

  static dynamic _containsImpl(WorkerRequest req) {
    return _getImpl(req) != null;
  }

  static void _setImpl(WorkerRequest req) {
    _cache[req.args[0]] = _CacheEntry._(req.args[1], req.args[2]);
  }
}

class _CacheEntry {
  _CacheEntry._(this._data, int? ttl)
      : _expires = (ttl == null || ttl <= 0)
            ? null
            : DateTime.now().add(Duration(microseconds: ttl));

  final dynamic _data;
  final DateTime? _expires;
}
