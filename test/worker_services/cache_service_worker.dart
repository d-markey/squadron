import 'dart:async';

import 'package:squadron/squadron.dart';

import '../src/test_context.dart';
import 'cache_service.dart';
import 'squadron_version.dart';

base class CacheWorker extends Worker with WorkerVersion implements Cache {
  CacheWorker(TestContext context) : super(context.entryPoints.cache!);

  @override
  Future<dynamic> get(dynamic key) => send(
        CacheService.getCommand,
        args: [key],
        inspectRequest: true,
        inspectResponse: true,
      );

  @override
  Future<bool> containsKey(dynamic key) =>
      send(CacheService.containsCommand, args: [key])
          .then(Squadron.converter.value<bool>());

  @override
  Future<dynamic> set(dynamic key, dynamic value, {Duration? timeToLive}) {
    assert(value != null); // null means not in cache; cannot store null
    return send(
      CacheService.setCommand,
      args: [key, value, timeToLive?.inMicroseconds],
      inspectRequest: true,
      inspectResponse: true,
    );
  }

  @override
  Future<CacheStat> getStats() async =>
      CacheStat.deserialize(await send(CacheService.statsCommand));
}
