import 'dart:async';

import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import 'cache_service.dart';

class CacheWorker extends Worker implements Cache {
  CacheWorker(TestContext context) : super(context.entryPoints.cache!);

  @override
  Future<dynamic> get(dynamic key) =>
      send(CacheService.getOperation, args: [key]);

  @override
  Future<bool> containsKey(dynamic key) =>
      send<bool>(CacheService.containsOperation, args: [key]);

  @override
  Future set(dynamic key, dynamic value, {Duration? timeToLive}) {
    assert(value != null); // null means not in cache; cannot store null
    return send(CacheService.setOperation,
        args: [key, value, timeToLive?.inMicroseconds]);
  }

  @override
  Future<CacheStat> getStats() async =>
      CacheStat.deserialize(await send(CacheService.statsOperation));
}
