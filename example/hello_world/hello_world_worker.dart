import 'dart:async';

import 'package:squadron/squadron.dart';

import 'hello_world.dart';
import 'hello_world_worker_service.dart';

/// Use squadron_builder to generate this code.
/// Manual implementation is discouraged.
///
/// See https://github.com/d-markey/squadron_builder/tree/main/example/hello_world
///
/// The service worker.
class HelloWorldWorker extends Worker implements HelloWorld {
  HelloWorldWorker(super.entryPoint,
      {super.args, super.threadHook, super.exceptionManager});

  /// Forward call to the service running in the worker thread.
  @override
  Future<String> sayHello(String? name,
          {int delayInSec = 0, bool echo = false}) =>
      send(HelloWorldWorkerService.$sayHello, args: [name, delayInSec, echo])
          .then((res) => res.toString());
}
