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

## Summary

* [Features](#features)
* [Flutter Demo](#demo)
* [Getting Started](#started)
* [Usage](#usage)
* [Remarks on Isolates / Web Workers](#remarks)
  * [Channels, Types, and Browser Platforms](#channels_and_types)
  * [Note on `package:json_annotation`](#json_annotation)
* [Scaling Options](#scaling)
* [Worker Cooperation](#cooperation)
* [Task Cancellation](#cancellation)
  * [Cancellation Tokens](#tokens)
* [Monitoring](#monitoring)
* [Logging](#logging)
* [Thanks!](#thanks)

## <a name="features"></a>Features

`Worker` class: a base worker class managing a platform thread (Isolate or Web Worker) and the communication between
clients and  workers.

`WorkerPool<W>` class: a worker pool for `W` workers. The number of workers is configurable as well as the degree of
concurrent workloads distributed to workers in the pool. Tasks posted to the worker pool may be cancelled.

## <a name="demo"></a>Flutter Demo

A demo is available from [GitHub: squadron_sample](https://github.com/d-markey/squadron_sample).

It provides a Flutter App running on native and browser platforms, showcasing Squadron integration with [Flutter](https://flutter.dev/).

## <a name="started"></a>Getting Started

Import squadron from your `pubspec.yaml` file:

```
dependencies:
   squadron: ^3.1.0
```

## <a name="usage"></a>Usage

First implement a service with sync or async methods you want to expose from workers. This approach enables reusing
the code in different scenarios: unit tests, direct call from your app, or wrapped in a native Isolate or in a Web
Worker.

The example below implements a `SampleService` with a synchronous `cpu()` method and an asynchronous `io()` method.
The service inherits from `WorkerService` and must implement the `operations` map. This collection is essentially a
dispatcher used to map service command ids with actual command handlers. Squadron uses this map in platform workers
to serve worker requests. The command handlers provided in this map are responsible for retrieving arguments from the
`WorkerRequest` message and providing them to the service method.

```dart
class SampleService implements WorkerService {
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
  @override
  Map<int, CommandHandler> get operations => {
    ioCommand: (WorkerRequest r) => io(milliseconds: r.args[0]),
    cpuCommand: (WorkerRequest r) => cpu(milliseconds: r.args[0]),
  };
}
```

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
}
```

The platform worker's main program can be implemented using the `run()` function provided by Squadron 3. The first
argument passed to this function is a `WorkerService` initializer responsible for creating the service to be used by
the platform worker. This function will be passed the first `WorkerRequest` to set up the service. The second argument
passed to `run()` is optional for Web applications, but required in native scenarios where it must be set to the data
passed to the `Isolate`'s main program.

* native implementation:

```dart
SampleWorker createVmSampleWorker() => SampleWorker(_main);

void _main(Map command) => run((startRequest) => SampleService(), command);
```

* browser implementation:

```dart
SampleWorker createJsSampleWorker() => SampleWorker('sample_worker_js.dart.js');

void main() => run((startRequest) => SampleService());
```

Using a `WorkerPool`, you are now able to distribute your workloads:

```dart
    var pool = WorkerPool(createVmSampleWorker, maxWorkers: 4, maxParallel: 2); /* native version */
    // var pool = WorkerPool(createJsSampleWorker, maxWorkers: 4, maxParallel: 2); /* browser version */
    await pool.start();

    var n = 42;
    var cpuResult = await pool.execute((w) => w.cpu(milliseconds: n));
    var ioResult = await pool.execute((w) => w.io(milliseconds: n));
```

## <a name="remarks"></a>Remarks on Isolates / Web Workers

While `Isolates` enable multithreading in Dart applications, several aspects must be taken into account:

* Creating an `Isolate` can be an expensive process.

* `Isolate` threads are still based on an event loop, processing asynchronous tasks/callbacks one by one.

* `Isolate`s do not share memory; in particular, global contexts are not shared across `Isolate`s and may
have to be initialized multiple times thus increasing the application's memory footprint and startup time.

* Communicating with an `Isolate` invoves marshalling data in and out; theoretically, only primitive types
(`num`, `String`, `bool`, `null`...), `List`/`Map` of primitive types and some specific types like `SendPort`
are supported. However, object instances may be sent across `Isolate`s on some platforms, e.g. the Dart
Native platform (instances will still be copied).

Web Workers have similar characteristics. Only primitive types and objects implementing
[Transferable](https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects) can be sent across
Web Worker boundaries.

### <a name="channels_and_types"></a>Channels, Types, and Browser Platforms

To provide a cross-platform development experience, Squadron encapsulates `Isolates` and `Web Workers` as
well as the means to communicate between the main app's code and the code they execute. This is achieved via
the `Channel` class.

![](channels_and_types.png)

`Channel` enables data exchange between threads and inherits the constraints of the target platforms, in
particular the type system. Dart Native platforms will typically be quite relaxed when communicating between
threads, even allowing custom Dart objects to come through.

**But JavaScript will not be so forgiving because JavaScript doesn't know about Dart types.**

To transfer a custom object, it must be serialized on the sender end and deserialized on the receiver end.
There are several ways of serializing a custom object, e.g. JSON structure holding the object's attributes,
or `String`/binary representation of the object...

However, when the data to be transfered hits the browser's Web Worker implementation, only basic type information
(number, boolean, string, array or map) is retained. In particular, generic types sent from one side will not be
received with the same generic type on the other end. For instance, when a sending a `List<String>` or a
`Map<String, dynamic>` to a service worker, browser platforms will provide the data to the worker service as
a bare `List` (= `List<dynamic>`) or a bare `Map` (= `Map<dynamic, dynamic>`). This is an important point to
ensure your app will run happily on browsers.

Serialization and deserialization should be done as close to the `Channel` as possible, typically when calling
the `send` method or when receiving data in the `operations` map.

For example, the approach below is a generic way to transfer custom objects via Squadron:

```dart
class ServiceResponse {
   static ServiceResponse deserialize(dynamic result) {
      // deserialize "result", knowing it was produced by serialize()
      // or call the code produced by package:json_annotation with anyMap = true
   }

   dynamic serialize() {
      // serialize using only base types or simple List/Map
      // or call the code produced by package:json_annotation with anyMap = true
   }
}

class ServiceRequest {
   static ServiceRequest deserialize(dynamic result) {
      // deserialize "result", knowing it was produced by serialize()
      // or call the code produced by package:json_annotation with anyMap = true
   }

   dynamic serialize() {
      // serialize using only base types or simple List/Map
      // or call the code produced by package:json_annotation with anyMap = true
   }
}

abstract class ServiceDefinition {
   FutureOr<ServiceResponse> serviceMethod(ServiceRequest request);

   static const cmdServiceMethod = 1;
}

class ServiceImplementation implements ServiceDefinition {
   @override
   ServiceResponse serviceMethod(ServiceRequest request) {
      // process the request and produce the response
   }

   // in the operations map, deserialize argument and serialize result

   @override
   late final Map<int, CommandHandler> operations = {
      ServiceDefinition.cmdServiceMethod: (WorkerRequest r) => serviceMethod(ServiceRequest.deserialize(r.args[0])).serialize();
   };
}

class ServiceWorker implements ServiceDefinition, WorkerService {

   // in the worker overrides, serialize argument and deserialize result

   @override
   ServiceResponse serviceMethod(ServiceRequest request) async
      => ServiceResponse.deserialize(await send(ServiceDefinition.cmdServiceMethod, [ request.serialize() ]));
}
```

### <a name="json_annotation"></a>Note on `package:json_annotation`

Packages such as [json_annotation](https://pub.dev/packages/json_annotation) / [json_serializable](https://pub.dev/packages/json_serializable)
can be used to generate the serialization and deserialization code for custom classes. By default, objects will be
serialized to / deserialized from `Map<String, dynamic>` data structures.

In Browser scenarios, this will lead to errors as the `Map<String, dynamic>` structures lose their strong types
as they are processed by the browser.

Luckily, [json_annotation](https://pub.dev/packages/json_annotation) provides the `anyMap` option to control code
generation: by setting `anyMap` to `true`, the code builders from [json_serializable](https://pub.dev/packages/json_serializable)
will handle JSON objects as `Map` instead of `Map<String, dynamic>`.

**Setting `anyMap` to `true` is mandatory for classes that are transferred to/from Squadron workers.**

## <a name="scaling"></a>Scaling Options

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

## <a name="cooperation"></a>Worker Cooperation

It is possible to implement some kind of worker cooperation and support more complex scenarios.

For instance, the fact that `Isolate`s and Web Workers do not share memory means it may be cumbersome to implement
a local, in-memory cache at worker level. Each worker would have their own cache, making expiration and update
propagation difficult to implement.

Such a cache can however be implemented as a Singleton, communicating with other workers by sharing its `Channel`
property (`Channel` objects can be sent across platform workers via the `serialize()` method).

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
class CacheService implements Cache, WorkerService {
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
class OtherService implements WorkerService {
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

  @override
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
  run((startRequest) {
    final cacheEndPoint = startRequest.args.isEmpty
        ? null
        : Channel.deserialize(startRequest.args[0]);
    Cache? cache = (cacheEndPoint == null) ? null : CacheClient(cacheEndPoint);
    return OtherService(cache);
  }, command);
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

## <a name="cancellation"></a>Task Cancellation

Tasks registered with the worker pool may be cancelled by calling `pool.cancel()`. A `CancelledException` will be
raised (for value tasks: the future completes with an error) or emitted (for streaming tasks: the stream will emit
an error) for each cancelled task. Tasks still pending will fail immediately; tasks already executing when the
`cancel()` method is called will either complete (value task) or emit an exception (streaming tasks).

It should be noted that implementations relying on `pool.cancel()` will not notify platform workers about the
cancellation. Tasks that have been assigned to a platform worker will continue executing until they complete. As a
result, a value task already executing cannot be cancelled this way: it will complete and return a value. The
situation is slightly different for a streaming task: while it will report cancellation in the main event loop,
streaming will continue in the platform worker's event loop.

```dart
  final future = pool.execute((w) => w.computeData());
  final stream = pool.stream((w) => w.streamData());

  // no async suspension means Squadron could not schedule any task
  // as a result this cancellation request will cancel both tasks
  pool.cancel();

  stream.listen(
    (value) => print('received value: $value'),   // will not be called
    onError: (e) => print('received error: $e')); // receives a CancelledException

  final result = await future; // throws a CancelledException
```

```dart
  final future = pool.execute((w) => w.computeData());
  final stream = pool.stream((w) => w.streamData());

  // asynchronous suspension gives Squadron a chance to schedule some tasks
  Future(() => null);

  // depending on concurrency settings, this cancellation request should cancel the stream task
  // however the value task should have been scheduled and should complete
  pool.cancel(); 

  stream.listen(
    (value) => print('received value: $value'),   // may be called for a few values
    onError: (e) => print('received error: $e')); // will receive a CancelledException

  final result = await future; // should get the task's result
```

It is also possible to schedule and cancel individual tasks, eg.:

```dart
  final valueTask = pool.scheduleTask((w) => w.computeData());
  final streamTask = pool.scheduleStream((w) => w.streamData());

  // no async suspension means Squadron could not schedule any task

  streamTask.cancel(); // or pool.cancel(streamTask)
  streamTask.stream.listen(
    (value) => print('received value: $value'),   // will not be called
    onError: (e) => print('received error: $e')); // receives a CancelledException

  valueTask.cancel(); // or pool.cancel(valueTask)
  final result = await valueTask.value; // throws a CancelledException
```

```dart
  final valueTask = pool.scheduleTask((w) => w.computeData());
  final streamTask = pool.scheduleStream((w) => w.streamData());

  // asynchronous suspension gives Squadron a chance to schedule some tasks
  Future(() => null);

  streamTask.cancel(); // or pool.cancel(streamTask)
  streamTask.stream.listen(
    (value) => print('received value: $value'),   // may be called for a few values
    onError: (e) => print('received error: $e')); // will receive a CancelledException

  valueTask.cancel(); // or pool.cancel(valueTask)
  final result = await valueTask.value;  // should get the task's result
```

### <a name="tokens"></a>Cancellation Tokens

To notify workers of the cancellation, Squadron 3 provides the generic `CancellationToken` class implementing the
base functionality for cancellation tokens. To ensure workers are notified of a token's cancellation, the token must
be provided to the worker. Cancellation notifications are posted to workers regardless of the `maxParallel` concurrency
settings. It is the responsibility of the worker service (your code) to verify the token status and abort processing
when requested. To ensure the cancellation can be processed, you code must therefore be asynchronous. If the service
is essentially CPU-bound, this can be achieved by awaiting a simple `Future(() {})`.

When a token is cancelled, all tasks associated with the token will be cancelled. A `CancelledException` will be
thrown and the code that started the worker task will receive it.

Squadron provides 3 kinds of cancellation tokens:
* `CancellableToken`: a cancellation token that can be triggered programmatically by calling
`CancellableToken.cancel()`.
* `TimeOutToken`: a cancellation token that will be cancelled automatically after a given duration. Timeout countdown
starts then the task is effectively posted to a worker.
* `CompositeToken`: a cancellation token monitoring several other tokens. A `CompositeToken` will be cancelled
automatically upon cancellation of one of the tokens (`CompositeMode.any`) or all of them (`CompositeMode.all`).

Example:

```dart
class SampleService implements WorkerService {
  Future io({required int milliseconds, CancellationToken? token}) async {
    if (token?.cancelled ?? false) throw CancelledException();
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  Future cpu({required int milliseconds, CancellationToken? token}) async {
    final sw = Stopwatch()..start();
    var count = 0;
    while (sw.elapsedMilliseconds < milliseconds) {
      if (count % 1000 == 0) {
        // avoid flooding the event loop with noop futures, check every 1000 iterations only
        if (token?.cancelled ?? false) throw CancelledException();
        await Future(() {});
      }
      count++;
    }
  }

  // command ids
  static const ioCommand = 1;
  static const cpuCommand = 2;

  // map of command ids to implementatons
  @override
  Map<int, CommandHandler> get operations => {
    ioCommand: (WorkerRequest r) => io(milliseconds: r.args[0], token: r.cancelToken),
    cpuCommand: (WorkerRequest r) => cpu(milliseconds: r.args[0], token: r.cancelToken),
  };
}
```

```dart
  // create a token
  final token = CancellableToken();
  // trigger cancellation after 500 ms
  // in real world, token.cancel() would be called in reaction to an event such as a user action for instance
  // this is similar to a timeout token except that countdown starts immediately
  Timer(Duration(milliseconds: 500), token.cancel);

  // start a computation lasting 1000 ms
  // pass the token to the service + the pool
  // a CancelledException will be thrown after 500 ms
  await pool.execute((w) => w.cpu(milliseconds: 1000, token));
```

Notes:

* the token received by workers will not have the same runtime type as the token passed to the worker. The
service code should not make any assumption on the token's runtime type and should only manipulate generic
`CancellationToken` objects.
* the same cancellation token may be used to control cancellation of several tasks.
* when using a `TimeOutToken`, the timeout countdown will only start when the task is effectively posted to the
worker for execution. If the token is shared across several tasks, the countdown starts with the first worker and
applies to all workers.

## <a name="monitoring"></a>Worker Monitoring

Monitoring workers in a pool can be done with a simple timer. For instance, to stop workers after a given idle
period:

```dart
  // install worker monitor
  final timer = Timer.periodic(refreshDuration, (timer) {
    pool.stop((w) => w.idleTime > maxIdle);
  });
```

Please note that some idle workers may remain alive, depending on the `minWorker` concurrency setting.

To stop all workers, simply call the pool's `stop()` method with no predicate.

```dart
  // stops all workers
  pool.stop();
```

All workers will be stopped as soon as all tasks registered with the pool have been processed. Of course, it
is possible to cancel pending tasks before stopping the worker pool.

```dart
  // cancels pending tasks and stops all workers
  pool.cancel();
  pool.stop();
```

The pool will not accept new tasks unless it is restarted with `pool.start()`. 

## <a name="logging"></a>Logging

Squadron provides a minimal logging infrastructure to facilitate logging and debugging. The interface to log
messages is similar to that of the [logging](https://pub.dev/packages/logging) package, including compatible
log levels.

To enable logging in the main application, simply set the appropriate log level and install a logger. Squadron
provides two simple loggers out of the box:
* `DevSquadronLogger` where messages are logged via `dart:developper`'s `log()`
* `ConsoleSquadronLogger` where messages are logged with `print()`

For instance:

```dart
// this is your main app entry point
void main() {
  Squadron.logLevel = SquadronLogLevel.WARNING;
  Squadron.logger = DevSquadronLogger();
  // ... and then the rest of your code
}
```

When your app fires up a worker, the log level will be passed on to the platform worker automatically. However,
Squadron does not automatically selects a logger and it has to be initialized manually. The logger should be
installed as early as possible in the worker's lifetime, for instance before calling the `run()` function, or
in the service initialization function.

Here are some examples:

* in native workers, use a `DevSquadronLogger`:

```dart
SampleWorker createVmSampleWorker() => SampleWorker(_main);

void _main(Map command) {
  Squadron.logger = DevSquadronLogger();
  run((startRequest) => SampleService(), command);
}
```

* in Web workers, use a `ConsoleSquadronLogger`:

```dart
SampleWorker createJsSampleWorker() => SampleWorker('sample_worker_js.dart.js');

void main() {
  Squadron.logger = ConsoleSquadronLogger();
  run((startRequest) => SampleService());
}
```

Web Workers are not connected to the Dart debugger. As a result, debugging them can be challenging.
`ConsoleSquadronLogger` will help and display log messages in your browser's JavaScript console.

## <a name="prod"></a>Releasing Your App

Releasing your application for Dart Native platforms should be straightforward.

To release the Browser version, the worker code must first be compiled to JavaScript:

```
dart compile js -o web/service_worker.dart.js lib/src/browser/service_worker.dart
```

You may also have to reference the JavaScript file from `index.html`:

```html
  <!-- Load service_worker.dart.js file -->
  <script>
    const scriptTag = document.createElement('script');
    scriptTag.src = 'service_worker.dart.js';
    scriptTag.defer = true;
    scriptTag.type = 'text/javascript';
    document.body.append(scriptTag);
  </script>
```

## <a name="thanks"></a>Thanks!

* [SwissCheese5](https://github.com/SwissCheese5) for his patience and feedback when implementing
Squadron into his Flutter application.
