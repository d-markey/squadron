import 'package:squadron/squadron.dart';

import 'hello_world.dart';

/// Use squadron_builder to generate this code.
/// Manual implementation is discouraged.
///
/// See https://github.com/d-markey/squadron_builder/tree/main/example/hello_world
///
/// The service implementation for workers.
class HelloWorldWorkerService extends HelloWorld implements WorkerService {
  /// Command ID for [sayHello], used in the [operations] map.
  static const $sayHello = 1;

  /// Map of commands.
  @override
  late final operations = OperationsMap({
    $sayHello: (WorkerRequest r) =>
        sayHello(r.args[0], delayInSec: r.args[1], echo: r.args[2]),
  });
}
