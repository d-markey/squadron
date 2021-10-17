import 'dart:async';

import 'package:squadron/squadron.dart';

abstract class Cache {
  FutureOr<dynamic> get(dynamic key);
  FutureOr<bool> containsKey(dynamic key);
  FutureOr set(dynamic key, dynamic value, {Duration? timeToLive});
  FutureOr<CacheStat> getStats();
}

class CacheClient implements Cache {
  CacheClient(this._remote);

  final Channel _remote;

  @override
  Future<dynamic> get(dynamic key) =>
      _remote.sendRequest(CacheService.getOperation, [key]);

  @override
  Future<bool> containsKey(dynamic key) =>
      _remote.sendRequest(CacheService.containsOperation, [key]);

  @override
  Future set(dynamic key, dynamic value, {Duration? timeToLive}) {
    assert(value != null); // null means not in cache; cannot store null
    return _remote.sendRequest(
        CacheService.setOperation, [key, value, timeToLive?.inMicroseconds]);
  }

  @override
  Future<CacheStat> getStats() async => CacheStat.deserialize(
      await _remote.sendRequest(CacheService.statsOperation, []));
}

class CacheWorker extends Worker implements Cache {
  CacheWorker(dynamic entryPoint, {String? id, List args = const []})
      : super(entryPoint, id: id, args: args);

  @override
  Future<dynamic> get(dynamic key) => send(CacheService.getOperation, [key]);

  @override
  Future<bool> containsKey(dynamic key) =>
      send(CacheService.containsOperation, [key]);

  @override
  Future set(dynamic key, dynamic value, {Duration? timeToLive}) {
    assert(value != null); // null means not in cache; cannot store null
    return send(
        CacheService.setOperation, [key, value, timeToLive?.inMicroseconds]);
  }

  @override
  Future<CacheStat> getStats() async =>
      CacheStat.deserialize(await send(CacheService.statsOperation));
}

class CacheService implements Cache, WorkerService {
  final _cache = <dynamic, _CacheEntry>{};

  int _hit = 0;
  int _miss = 0;
  int _expired = 0;
  int get size => _cache.length;
  int _maxSize = 0;

  @override
  dynamic get(dynamic key) {
    final entry = _cache[key];
    if (entry == null) {
      // not in cache
      _miss++;
      return null;
    } else if (entry._expires == null ||
        entry._expires!.isBefore(DateTime.now())) {
      // in cache, still valid
      _hit++;
      return entry._data;
    } else {
      // in cache, expired
      _cache.remove(key);
      _expired++;
      return null;
    }
  }

  @override
  bool containsKey(dynamic key) {
    // don't use _cache.containsKey()
    // use get() as it implements the expiration logic
    final data = get(key);
    return data != null;
  }

  @override
  void set(dynamic key, dynamic value, {Duration? timeToLive}) {
    _cache[key] = _CacheEntry._(value, timeToLive?.inMicroseconds);
    if (_cache.length > _maxSize) {
      _maxSize = _cache.length;
    }
  }

  @override
  CacheStat getStats() {
    return CacheStat(_hit, _miss, _expired, size, _maxSize);
  }

  static const getOperation = 1;
  static const containsOperation = 2;
  static const setOperation = 3;
  static const statsOperation = 4;

  @override
  Map<int, CommandHandler> get operations => {
        getOperation: (r) => get(r.args[0]),
        containsOperation: (r) => containsKey(r.args[0]),
        setOperation: (r) => set(r.args[0], r.args[1],
            timeToLive:
                (r.args[2] == null) ? null : Duration(microseconds: r.args[2])),
        statsOperation: (r) => getStats().serialize()
      };
}

class _CacheEntry {
  _CacheEntry._(this._data, int? ttl)
      : _expires = (ttl == null || ttl <= 0)
            ? null
            : DateTime.now().add(Duration(microseconds: ttl));

  final dynamic _data;
  final DateTime? _expires;
}

class CacheStat {
  CacheStat(this.hit, this.miss, this.expired, this.size, this.maxSize);

  CacheStat.deserialize(List<int> data)
      : hit = data[0],
        miss = data[1],
        expired = data[2],
        size = data[3],
        maxSize = data[4];

  final int hit;
  final int miss;
  final int expired;
  final int size;
  final int maxSize;

  List<int> serialize() => [hit, miss, expired, size, maxSize];

  @override
  String toString() =>
      'hit = $hit, miss = $miss, expired = $expired, size = $size, maxSize = $maxSize';
}
