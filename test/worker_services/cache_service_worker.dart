import 'dart:async';

import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import 'cache_service.dart';

base class CacheWorker extends Worker implements Cache {
  CacheWorker(TestContext context) : super(context.entryPoints.cache!);

  @override
  Future<dynamic> get(dynamic key) => send(
        CacheService.getOperation,
        args: [key],
        inspectRequest: true,
        inspectResponse: true,
      );

  @override
  Future<bool> containsKey(dynamic key) =>
      send(CacheService.containsOperation, args: [key])
          .then(Squadron.converter.value<bool>());

  @override
  Future<dynamic> set(dynamic key, dynamic value, {Duration? timeToLive}) {
    assert(value != null); // null means not in cache; cannot store null
    return send(
      CacheService.setOperation,
      args: [key, value, timeToLive?.inMicroseconds],
      inspectRequest: true,
      inspectResponse: true,
    );
  }

  @override
  Future<CacheStat> getStats() async =>
      CacheStat.deserialize(await send(CacheService.statsOperation));
}
