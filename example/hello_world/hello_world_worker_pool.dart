import 'dart:async';

import 'package:squadron/squadron.dart';

import 'hello_world.dart';
import 'hello_world_worker.dart';

/// Use squadron_builder to generate this code.
/// Manual implementation is discouraged.
///
/// See https://github.com/d-markey/squadron_builder/tree/main/example/hello_world
///
////// The service worker pool.
class HelloWorldWorkerPool extends WorkerPool<HelloWorldWorker>
    implements HelloWorld {
  HelloWorldWorkerPool(EntryPoint entryPoint,
      {PlatformThreadHook? threadHook,
      ConcurrencySettings? concurrencySettings})
      : super(
            (ExceptionManager exceptionManager) => HelloWorldWorker(
                  entryPoint,
                  threadHook: threadHook,
                  exceptionManager: exceptionManager,
                ),
            concurrencySettings: concurrencySettings);

  /// Forward call to one of the pool's worker.
  @override
  Future<String> sayHello(String? name,
          {int delayInSec = 0, bool echo = false}) =>
      execute((w) => w.sayHello(name, delayInSec: delayInSec, echo: echo));
}
