import 'dart:async';

import 'package:squadron/squadron.dart';

import 'squadron_version.dart';

abstract class Cache with SquadronVersion {
  FutureOr<dynamic> get(dynamic key);
  FutureOr<bool> containsKey(dynamic key);
  FutureOr<void> set(dynamic key, dynamic value, {Duration? timeToLive});
  FutureOr<CacheStat> getStats();
}

class CacheClient with SquadronVersion implements Cache {
  CacheClient(this._remote);

  final Channel _remote;

  static CacheClient? connect(Channel? remote) =>
      (remote == null) ? null : CacheClient(remote);

  @override
  Future<dynamic> get(dynamic key) =>
      _remote.sendRequest(CacheService.getCommand, [key]);

  @override
  Future<bool> containsKey(dynamic key) =>
      _remote.sendRequest(CacheService.containsCommand, [key]).then(
          Squadron.converter.value<bool>());

  @override
  Future set(dynamic key, dynamic value, {Duration? timeToLive}) {
    assert(value != null); // null means not in cache; cannot store null
    return _remote.sendRequest(
        CacheService.setCommand, [key, value, timeToLive?.inMicroseconds]);
  }

  @override
  Future<CacheStat> getStats() async => CacheStat.deserialize(
      await _remote.sendRequest(CacheService.statsCommand, []));
}

class CacheService with SquadronVersion implements Cache, WorkerService {
  CacheService();

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
        entry._expires.isBefore(DateTime.now())) {
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
  CacheStat getStats() => CacheStat(_hit, _miss, _expired, size, _maxSize);

  static const getCommand = 1;
  static const containsCommand = 2;
  static const setCommand = 3;
  static const statsCommand = 4;

  @override
  late final operations = OperationsMap({
    SquadronVersion.versionCommand: (r) => getVersion(),
    getCommand: (r) => get(r.args[0]),
    containsCommand: (r) => containsKey(r.args[0]),
    setCommand: (r) => set(r.args[0], r.args[1],
        timeToLive: (r.args[2] == null)
            ? null
            : Duration(
                microseconds: Squadron.converter.value<int>()(r.args[2]))),
    statsCommand: (r) => getStats().serialize()
  });
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

  CacheStat.deserialize(List data)
      : hit = (data[0] as num).toInt(),
        miss = (data[1] as num).toInt(),
        expired = (data[2] as num).toInt(),
        size = (data[3] as num).toInt(),
        maxSize = (data[4] as num).toInt();

  final int hit;
  final int miss;
  final int expired;
  final int size;
  final int maxSize;

  List serialize() => [hit, miss, expired, size, maxSize];
}
