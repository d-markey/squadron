Multithreading and worker pools in Dart

## Features

`Worker` class: a base worker class managing an Isolate and the communication from clients to the worker's Isolate.

`WorkerPool<W>` class: a worker pool for `W` workers. The number of workers is configurable as well as the degree of concurrent workloads distributed to workers in the pool.

## Getting Started

Import squadron from your `pubspec.yaml` file:

```
dependencies:
   squadron: ^1.0.2
```

## Usage

First implement a worker to offload specific tasks.

The example below implements a `cpuOperation()` method (where processing is essentially CPU-bound) and a `ioOperation()` method (where processing is essentially I/O-bound).

```dart
import 'dart:async';
import 'dart:isolate';

import 'package:squadron/squadron.dart';

class SampleWorker extends Worker {
  SampleWorker() : super(SampleWorker._main);

  @override
  final startArguments = [];

  Future<int> cpuOperation(int number)
    => send<int>(_cpuOperation, [number]);

  Future<int> ioOperation(int number) {
    => send<int>(_ioOperation, [number]);

  // private implementation, this is the thread's main program
  static void _main(List command) {
    final receiver = ReceivePort();
    WorkerRequest.fromMessage(command).connect(receiver);

    receiver.listen((command) async {
      WorkerRequest? req;
      try {
        req = WorkerRequest.fromMessage(command);
        if (req.command == null) {
          receiver.close();
          return;
        }
        final op = _operations[req.command];
        if (op == null) {
          req.exception(WorkerException('unknown command ${req.command}'),
              StackTrace.current);
          return;
        }
        req.reply(await op!(req));
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

  static const _cpuOperation = 1;
  static const _ioOperation = 2;

  static final Map<int, FutureOr<dynamic> Function(WorkerRequest req)>
      _operations = {
    _cpuOperation: _cpuOperationImpl,
    _ioOperation: _ioOperationImpl,
  };

  static int _cpuOperationImpl(WorkerRequest req) {
    var start = DateTime.now().millisecondsSinceEpoch;
    var elapsed = 0;
    while (elapsed < 2) {
      elapsed = DateTime.now().millisecondsSinceEpoch - start;
    }
    return req.args[0];
  }

  static Future<int> _ioOperationImpl(WorkerRequest req) {
    await Future.delayed(Duration(milliseconds: 2));
    return req.args[0];
  }
}
```

You can then distribute workloads to a worker pool, e.g.:

```dart
    var pool = WorkerPool(() => SampleWorker(), maxWorkers: 4, maxParallel: 2);
    await pool.start();

    var n = 42;
    var cpuResult = await pool.compute((w) => w.cpuOperation(n));
    var ioResult = await pool.compute((w) => w.ioOperation(n));
```

## Remarks on Isolates

While `Isolates` enable multithreading in Dart applications, several aspects must be taken into account:

* Creating an `Isolate` can be an expensive process.

* `Isolate` threads are still based on an event loop, processing asynchronous tasks/callbacks one by one.

* `Isolate`s do not share memory; in particular, global contexts are not shared across `Isolate`s and may
have to be initialized multiple times thus increasing the application's memory footprint and startup time.

* Communicating with an `Isolate` invoves marshalling data in and out; theoretically, only base types (`num`,
`String`, `bool`, `null`...) and `List`/`Map` of base types are supported. However, object instances may be
sent across `Isolate`s on some platforms, e.g. the Dart Native platform (instances will still be copied).

## Scaling Options

Squadron pools manage a collection of workers to avoid the cost of creating a new `Isolate` each time. Squadron
also implements a simple load-balancing mechanism and posts new tasks to workers that are most available (i.e.
those with the minimum `workload`, provided `workload` < `maxParallel`). Tasks in Squadron do not have a priority
and will be handled in the order they were received.

Depending on the type of processing, scaling tasks with Squadron can be achieved horizontally (adding new workers)
or vertically (distributing more tasks to workers).

* For pure CPU-bound tasks, e.g. image/video or other heavy data processing, increasing the `maxParallel` pool option
is likely to NOT yield any benefit for performance. If the event loop is already busy executing a task, subsequent
task requests posted to the `Worker` will not be handled before the executing task is complete. As a result,
CPU-bound tasks will be queued and scaling CPU workloads can only be achieved by adding more workers to the pool
(horizontal scaling). 

* For I/O bound tasks, performance benefits are less obvious. However, if processing requires many I/O operations,
offloading such tasks to a worker pool is likely to be beneficial because I/O callbacks will be registered with
the worker's `Isolate`. This scenario can be interesting in Web application back-ends to make the main event loop
more available for other incoming requests -- simple requests e.g. CRUD operations can be fully handled by the main
event loop while more complex, long-running, I/O-bound tasks will be processed off the Web app's main event loop.
Scaling such tasks can be achieved by increasing the `maxParallel` (vertical scaling) or `maxWorkers` (horizontal 
scaling) pool options. In I/O scenarios, vertical scaling should be preferred.

## Worker Cooperation

It is possible to implement some kind of worker cooperation and support more complex scenarios.

For instance, the fact that `Isolate`s do not share memory means it may be counterproductive to implement a local,
in-memory cache at worker level. Each worker would have their own copy of the cache, making expiration and update
propagation awkward to implement.

As a workaround, it is possible to implement a cache worker as a Singleton (no pooling) and to share the worker's
send port across other workers (`SendPort` objects can be sent to an `Isolate`).

An example is provided in `cache_worker.dart`. To access the cache API seamlessly, an abstract class is first
defined:

```dart
abstract class Cache {
  Future<dynamic> get(dynamic key);
  Future<bool> containsKey(dynamic key);
  Future set(dynamic key, dynamic value, { Duration? timeToLive });
}
```

A cache worker is then implemented (internal details skipped, please refer to the example source code):

```dart
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
  Future set(dynamic key, dynamic value, { Duration? timeToLive }) {
    assert(value != null); // null means not in cache; cannot store null
    return send(_set, [key, value, timeToLive?.inMicroseconds]);
  }

  // ...
}
```

Finally, a cache client is implemented to proxy calls directly to the cache `Isolate`:

```dart
class CacheClient implements Cache {
  CacheClient(this._remote);

  final SendPort _remote;

  @override
  Future<dynamic> get(dynamic key)
    => WorkerRequest(CacheWorker._get, [key]).send(_remote);

  @override
  Future<bool> containsKey(dynamic key)
    => WorkerRequest(CacheWorker._contains, [key]).send<bool>(_remote);

  @override
  Future set(dynamic key, dynamic value, { Duration? timeToLive })
    => WorkerRequest(CacheWorker._set, [key, value, timeToLive?.inMicroseconds]).send(_remote);
}
```

Sharing the cache across a pool of other workers comes down to advertising the `CacheWorker`'s `SendPort` so that
workers can create a cache client instance in their main program.

```dart
class OtherWorker extends Worker {
  OtherWorker([CacheWorker? cache]) : super(OtherWorker._main) {
    // the cache's SendPort will be provided to the Isolate's event loop via startArguments
    startArguments.add(cache?.workerPort);
  }

  Future<int> getFromCacheOrCompute(int inputData)
    => send<int>(0, inputData);

  @override
  final startArguments = [];

  static void _main(List command) {
    final receiver = ReceivePort();
    final req = WorkerRequest.fromMessage(command);
    req.connect(receiver);

    // create a cache instance if the worker was instantiated with a CacheWorker parameter
    Cache? cache;
    if (req.args[0] is SendPort) {
      cache = CacheClient(req.args[0]);
    }

    receiver.listen((command) {
      final req = WorkerRequest.fromMessage(command);
      if (req.command == null) {
        // stop request
        receiver.close();
      } else if (req.command == 0) {
        // computation request with cache
        req.reply(await _getFromCacheOrCompute(req.args[0], cache));
      } else {
        // ignore
        req.reply();
      }
    });
  }

  static Future<int> _getFromCacheOrCompute(int n, Cache? cache) {
    var result = await cache?.get(n);
    if (result == null) {
      result = _crunch(n);
      cache?.set(n, Duration(hours: 6));
    }
    return result;
  }
}
```

The application's main program is responsible for:

* setting up the `CacheWorker` Singleton
* setting up a pool of `OtherWorker`s and make sure the worker factory function passes the `CacheWorker` Singleton
to `OtherWorker`s.

```dart
final cacheWorker = CacheWorker();
await cacheWorker.start();

final pool = WorkerPool(() => OtherWorker(cacheWorker), minWorkers: 2, maxWorkers: 5);
await pool.start();
```


```
Architecture Diagram

                                   +-----------------------+
                              +--> | CacheWorker singleton | <--+
                              |    +-----------------------+    |
                              |                                 |
 +-------------------+        |           +----------------+   (4)
 |  main program     | --(1)--+    +----> | otherWorker #1 |    |
 |  ---------------- |             |      | -------------- |    |
(2) OtherWorker pool | --(3)--+    |      | cacheClient #1 | ---|
 +-------------------+        |    |      +----------------+    |
                              +----|                            |
                                   |      +----------------+    |
                                   +----> | otherWorker #2 |    |
                                          | -------------- | ---+
                                          | cacheClient #2 |
                                          +----------------+

1: the main program first spawns a CacheWorker
2: the main program creates a pool of OtherWorkers, making sure the CacheWorker Singleton is advertized to OtherWorkers when they are created
3: the pool creates new OtherWorkers as workload builds up, instantiating cache clients bound to the CacheWorker's SendPort
4: OtherWorkers query the CacheWorker via their local CacheClient to avoid expensive computations that have been done already 
```

## Worker Monitoring

Monitoring workers in a pool can be done with a simple timer. For instance, to stop workers after a given idle
period:

```dart
  // install worker monitor
  final timer = Timer.periodic(refreshDuration, (timer) {
    pool.stop((w) => w.idleTime > maxIdle);
  });
```

Please note that some idle workers may remain alive, depending on the `minWorker` pool option.
