[![Dart Workflow](https://github.com/d-markey/squadron/actions/workflows/dart.yml/badge.svg)](https://github.com/d-markey/squadron/actions/workflows/dart.yml)
[![Pub Package](https://img.shields.io/pub/v/squadron.svg?logo=dart&logoColor=00b9fc)](https://pub.dev/packages/squadron)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Dart Style](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)
[![Last Commits](https://img.shields.io/github/last-commit/d-markey/squadron?logo=git&logoColor=white)](https://github.com/d-markey/squadron/commits)
[![Code Size](https://img.shields.io/github/languages/code-size/d-markey/squadron?logo=github&logoColor=white)](https://github.com/d-markey/squadron)
[![License](https://img.shields.io/github/license/d-markey/squadron?logo=open-source-initiative&logoColor=green)](https://github.com/d-markey/squadron/blob/master/LICENSE)
[![GitHub Repo Stars](https://img.shields.io/github/stars/d-markey/squadron)](https://github.com/d-markey/squadron/stargazers)

Multithreading and worker pools in Dart to offload CPU-bound or long running tasks and give your mobile and Web apps
some air.

## Features

`Worker` class: a base worker class managing a platform thread (Isolate or Web Worker) and the communication between
clients and  workers.

`WorkerPool<W>` class: a worker pool for `W` workers. The number of workers is configurable as well as the degree of
concurrent workloads distributed to workers in the pool.

## Getting Started

Import squadron from your `pubspec.yaml` file:

```
dependencies:
   squadron: ^2.0.2
```

## Usage

First implement a service with sync or async methods you want to expose from workers. This approach enables reusing
the code in different scenarios: unit tests, direct call from your app, or wrapped in a native Isolate or in a Web
Worker.

The example below implements a `SampleService` with a synchronous `cpu()` method and an asynchronous `io()` method.

```dart
class SampleService {
  Future io({required int milliseconds}) =>
      Future.delayed(Duration(milliseconds: milliseconds));

  void cpu({required int milliseconds}) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < milliseconds) {/* cpu */}
  }

  // command ids
  static const ioCommand = 1;
  static const cpuCommand = 2;

  // map of command ids to implementatons
  Map<int, CommandHandler> get operations => {
    ioCommand: (WorkerRequest r) => io(milliseconds: r.args[0]),
    cpuCommand: (WorkerRequest r) => cpu(milliseconds: r.args[0]),
  };
}
```

The `operations` getter implemented in the service will be used by platform workers to dispatch incoming requests to
the right method. The command handlers provided in this map are also responsible for retrieving arguments from the
`WorkerRequest` message and providing them to the service methods.

This `SampleService` can easily be used as a contract to implemented the `Worker`. This worker can then be used for
Dart Isolates as well as Web Workers.

```dart
class SampleWorker extends Worker implements SampleService {
  SampleWorker(dynamic entryPoint, {String? id, List args = const []})
      : super(entryPoint, id: id, args: args);

  @override
  Future io({required int milliseconds}) =>
      send(SampleService.ioCommand, [milliseconds]);

  @override
  Future cpu({required int milliseconds}) =>
      send(SampleService.cpuCommand, [milliseconds]);

  // not used in Workers, just return an empty map
  @override
  final Map<int, CommandHandler> operations = const {};
}
```

If the requirements above are met, the Isolate's main program can be implemented like this:

```dart
SampleWorker createVmSampleWorker() => SampleWorker(_main);

void _main(Map command) {
  final operations = <int, CommandHandler>{};

  final workerPort = ReceivePort();
  workerPort.listen((command) {
    final req = WorkerRequest.deserialize(command);
    if (req.terminate) {
      Isolate.current.kill(priority: Isolate.immediate);
    } else {
      Worker.process(operations, req);
    }
  });

  final startRequest = WorkerRequest.deserialize(command);
  assert(startRequest.connect == true);
  Worker.connect(startRequest.client, workerPort,
      operations: operations, serviceOperations: SampleService().operations);
}
```

And the Web Worker version is just as easy:

```dart
SampleWorker createSampleWorker() => SampleWorker('sample_worker_js.dart.js');

void main() {
  final scope = DedicatedWorkerGlobalScope.instance;
  final operations = <int, CommandHandler>{};

  final com = MessageChannel();
  com.port1.onMessage.listen((MessageEvent e) {
    final req = WorkerRequest.deserialize(e.data);
    if (req.terminate) {
      scope.close();
    } else {
      Worker.process(operations, req);
    }
  });

  scope.onMessage.listen((MessageEvent e) {
    final startRequest = WorkerRequest.deserialize(e.data);
    assert(startRequest.connect == true);
    Worker.connect(startRequest.client, com.port2,
        operations: operations, serviceOperations: SampleService().operations);
  });
}
```

Using a `WorkerPool`, you are now able to distribute your workloads:

```dart
    var pool = WorkerPool(() => createSampleWorker(), maxWorkers: 4, maxParallel: 2);
    await pool.start();

    var n = 42;
    var cpuResult = await pool.compute((w) => w.cpu(milliseconds: n));
    var ioResult = await pool.compute((w) => w.io(milliseconds: n));
```

## Remarks on Isolates / Web Workers

While `Isolates` enable multithreading in Dart applications, several aspects must be taken into account:

* Creating an `Isolate` can be an expensive process.

* `Isolate` threads are still based on an event loop, processing asynchronous tasks/callbacks one by one.

* `Isolate`s do not share memory; in particular, global contexts are not shared across `Isolate`s and may
have to be initialized multiple times thus increasing the application's memory footprint and startup time.

* Communicating with an `Isolate` invoves marshalling data in and out; theoretically, only primitive types
(`num`, `String`, `bool`, `null`...) and `List`/`Map` of primitive types are supported. However, object
instances may be sent across `Isolate`s on some platforms, e.g. the Dart Native platform (instances will
still be copied).

Web Workers have similar characteristics. Only primitive types and objects implementing
[Transferable](https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects) can be sent across
Web Worker boundaries.

## Scaling Options

Squadron pools manage a collection of workers to avoid the cost of creating a new platform worker each time.
Squadron also implements a simple load-balancing mechanism and posts new tasks to workers that are most
available (i.e. those with the minimum `workload`, provided `workload` < `maxParallel`). Tasks in Squadron
do not have a priority and will be handled in the order they were received.

Depending on the type of processing, scaling tasks with Squadron can be achieved horizontally (adding new
workers) or vertically (distributing more tasks to workers).

* For pure CPU-bound tasks, e.g. image/video or other heavy data processing, increasing the `maxParallel` pool
option is likely to NOT yield any benefit for performance. If the event loop is already busy executing a task,
subsequent task requests posted to the `Worker` will not be handled before the executing task is complete. As a
result, CPU-bound tasks will be queued and scaling CPU workloads can only be achieved by adding more workers to
the pool (horizontal scaling). 

* For I/O bound tasks, performance benefits are less obvious. However, if processing requires many I/O operations,
offloading such tasks to a worker pool is likely to be beneficial because I/O callbacks will be registered with
the platform worker's event loop. This scenario can be interesting in Web application back-ends to make the main
event loop more available for other incoming requests -- simple requests e.g. CRUD operations can be fully handled
by the main event loop while more complex, long-running, I/O-bound tasks will be processed off the Web app's main
event loop. Scaling such tasks can be achieved by increasing the `maxParallel` (vertical scaling) or `maxWorkers`
(horizontal scaling) pool options. In I/O scenarios, vertical scaling should be preferred.

## Worker Cooperation

It is possible to implement some kind of worker cooperation and support more complex scenarios.

For instance, the fact that `Isolate`s and Web Workers do not share memory means it may be cumbersome to implement
a local, in-memory cache at worker level. Each worker would have their own copy of the cache, making expiration and
update propagation difficult to implement.

As a workaround, it is possible to implement a cache worker as a Singleton (no pooling) and to share the worker's
`Channel` across other workers (`Channel` objects can be sent across platform workers via the `serialize()` method).

An example is provided in `cache_worker.dart`. To access the cache API seamlessly, an abstract class is first
defined:

```dart
abstract class Cache {
  FutureOr<dynamic> get(dynamic key);
  FutureOr<bool> containsKey(dynamic key);
  FutureOr set(dynamic key, dynamic value, {Duration? timeToLive});
  FutureOr<CacheStat> getStats();
}
```

A cache service is then implemented (internal details skipped, please refer to the example source code). Note that
the `CacheService` implementation can be synchronous.

```dart
class CacheService implements Cache {
  @override
  dynamic get(dynamic key) {
    // retrieve the value associated for the specified key
    // return null if key is not in cache or if the key has expired
  }

  @override
  bool containsKey(dynamic key) {
    // use get() as it implements the expiration logic
    final data = get(key);
    return data != null;
  }

  @override
  void set(dynamic key, dynamic value, {Duration? timeToLive}) {
    // cache the value with the specified key and TTL
  }

  @override
  CacheStat getStats() {
    // return cache stats
  }

  // command ids
  static const getOperation = 1;
  static const containsOperation = 2;
  static const setOperation = 3;
  static const statsOperation = 4;

  // command handlers
  Map<int, CommandHandler> get operations => {
        getOperation: (WorkerRequest r) => get(r.args[0]),
        containsOperation: (WorkerRequest r) => containsKey(r.args[0]),
        setOperation: (WorkerRequest r) => set(r.args[0], r.args[1],
            timeToLive: (r.args[2] == null) ? null : Duration(microseconds: r.args[2])),
        statsOperation: (WorkerRequest r) => getStats().serialize()
      };
}
```

The `CacheWorker` is easy:

```dart
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
    return send(CacheService.setOperation, [key, value, timeToLive?.inMicroseconds]);
  }

  @override
  Future<CacheStat> getStats() async =>
      CacheStat.deserialize(await send(CacheService.statsOperation));
}
```

Finally, a cache client is implemented to proxy calls from other workers to the `CacheWorker`. This `CacheClient`
can be constructed with a `Channel` that will be obtained from the `CacheWorker`. 

```dart
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
  Future<CacheStat> getStats() async {
      => CacheStat.deserialize(
        await _remote.sendRequest(CacheService.statsOperation, []));
}
```

Note how `getStats()` implementations require serialization/deserialization of the `CacheStat` object. This is
necessary to cross platform worker boundaries.

```dart
class OtherService {
  OtherService([this._cache]);

  final Cache? _cache;

  // some service method
  Future<int> compute(int n) async {
    // check cache
    int? result = await _cache?.get(n);
    if (result != null) {
      // cache hit
      return n;
    }
    // otherwise compute
    // ...
    // finally, cache (dont await) and return
    cache?.set(n, result);
    return result!;
  }

  // some command ids
  static const computeCommand = 1;

  Map<int, CommandHandler> get operations => {
    // the comand handlers for the command ids
    computeCommand: (r) => compute(r.args[0])
  };
}
```

The `OtherWorker` implementation is straightforward:

```dart
class OtherWorker extends Worker implements OtherService {
  OtherWorker(dynamic entryPoint, {String? id, List args = const []})
      : super(entryPoint, id: id, args: args);

  @override
  Future<int> compute(int n) => send<int>(OtherService.computeCommand, [n]);

  // other proxy service methods...

  @override
  final Cache? _cache = null;

  @override
  final Map<int, CommandHandler> operations = const {};
}
```

The platform worker assembles everything. It is essentially the same as above, with some extra initialization code
to set up a `CacheClient`.

To create a `CacheClient` from within the platform worker, the `CacheWorker`'s `Channel` must be somehow passed to
the `OtherWorker`. This is done using the `share()` and the `serialize()` methods provided by `Channel`. These
methods will return an opaque object that can be safely sent across workers and deserialized to recreate a
`Channel`, thereby bridging the gap between the `OtherService` instances and the `CacheService` Singleton.

```dart
OtherWorker createOtherWorker([CacheWorker? cache]) =>
    OtherWorker(_main, args: [cache?.channel?.share().serialize()]);

void _main(Map command) {
  final operations = <int, CommandHandler>{};

  final workerPort = ReceivePort();
  workerPort.listen((command) {
    final req = WorkerRequest.deserialize(command);
    if (req.terminate) {
      Isolate.current.kill(priority: Isolate.immediate);
    } else {
      Worker.process(operations, req);
    }
  });

  final startRequest = WorkerRequest.deserialize(command);
  assert(startRequest.connect == true);
  final cacheEndPoint = startRequest.args.isEmpty
      ? null
      : Channel.deserialize(startRequest.args[0]);
  Cache? cache = (cacheEndPoint == null) ? null : CacheClient(cacheEndPoint);
  Worker.connect(startRequest.client, workerPort,
      operations: operations,
      serviceOperations: OtherService(cache).operations);
}
```

The application's main program is responsible for:

* setting up the `CacheWorker` Singleton
* setting up a pool of `OtherWorker`s and making sure the worker factory function receives the `CacheWorker`
Singleton.

```dart
final cacheWorker = CacheWorker();
await cacheWorker.start();

final pool = WorkerPool(() => createOtherWorker(cacheWorker), minWorkers: 2, maxWorkers: 5);
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
                                          | -------------- |    |
                                          | cacheClient #2 | ---+
                                          +----------------+

1: the main program first spawns a CacheWorker
2: the main program creates a pool of OtherWorkers, making sure the CacheWorker Singleton is advertized to OtherWorkers when they are created
3: the pool creates new OtherWorkers as workload builds up, instantiating cache clients bound to the CacheWorker's Channel
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

To kill all workers, simply call the pool's `stop()` method with no predicate.

```dart
  // kills all workers
  pool.stop();
```
