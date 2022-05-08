[![Pub Package](https://badgen.net/pub/v/squadron)](https://pub.dev/packages/squadron)
[![Dart Platforms](https://badgen.net/pub/dart-platform/squadron)](https://pub.dev/packages/squadron)
[![Flutter Platforms](https://badgen.net/pub/flutter-platform/squadron)](https://pub.dev/packages/squadron)

[![License](https://badgen.net/pub/license/squadron)](https://github.com/d-markey/squadron/blob/master/LICENSE)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Dart Style](https://img.shields.io/badge/style-lints-40c4ff)](https://pub.dev/packages/lints)
[![Pub Points](https://badgen.net/pub/points/squadron)](https://pub.dev/packages/squadron/score)
[![Likes](https://badgen.net/pub/likes/squadron)](https://pub.dev/packages/squadron/score)
[![Popularity](https://badgen.net/pub/popularity/squadron)](https://pub.dev/packages/squadron/score)

[![Last Commit](https://img.shields.io/github/last-commit/d-markey/squadron?logo=git&logoColor=white)](https://github.com/d-markey/squadron/commits)
[![Dart Workflow](https://github.com/d-markey/squadron/actions/workflows/dart.yml/badge.svg?logo=dart)](https://github.com/d-markey/squadron/actions/workflows/dart.yml)
[![Code Lines](https://img.shields.io/badge/dynamic/json?color=blue&label=code%20lines&query=%24.linesValid&url=https%3A%2F%2Fraw.githubusercontent.com%2Fd-markey%2Fsquadron%2Fmain%2Fcoverage.json)](https://github.com/d-markey/squadron/tree/main/coverage/html)
[![Code Coverage](https://img.shields.io/badge/dynamic/json?color=blue&label=code%20coverage&query=%24.lineRate&suffix=%25&url=https%3A%2F%2Fraw.githubusercontent.com%2Fd-markey%2Fsquadron%2Fmain%2Fcoverage.json)](https://github.com/d-markey/squadron/tree/main/coverage/html)

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
  * [Local Workers](#local_worker)
* [Task Cancellation](#cancellation)
  * [Cancellation Tokens](#tokens)
* [Monitoring](#monitoring)
* [Logging](#logging)
* [Thanks!](#thanks)

## <a name="features"></a>Features

`Worker`: a base worker class managing a platform thread (Isolate or Web Worker) and the communication between
clients and  workers.

`WorkerPool<W>`: a worker pool for `W` workers. The number of workers is configurable as well as the degree of
concurrent workloads distributed to workers in the pool. Tasks posted to the worker pool can be cancelled.

## <a name="demo"></a>Flutter Demo

A demo is available from [GitHub: squadron_sample](https://github.com/d-markey/squadron_sample).

It provides a Flutter App running on native and browser platforms, showcasing Squadron integration with [Flutter](https://flutter.dev/).

## <a name="started"></a>Getting Started

Import squadron from your `pubspec.yaml` file:

```yaml
dependencies:
   squadron: ^4.0.0
```

## <a name="usage"></a>Usage

**The basic idea behind Squadron is to wrap a set of service methods in a cross-platform Worker, enabling seamless
access to the service API from both Native and Browser platforms.**

To implement this pattern, the best way to go is to first implement a service with sync or async methods you want to
expose from workers. This approach enables reusing the code in different scenarios: unit tests, direct call from your
app, or wrapped in a native `Isolate` or in a Web `Worker`.

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

  // command IDs
  static const ioCommand = 1;
  static const cpuCommand = 2;

  // command IDs --> command implementations
  @override
  Map<int, CommandHandler> get operations => {
    ioCommand: (WorkerRequest r) => io(milliseconds: r.args[0]),
    cpuCommand: (WorkerRequest r) => cpu(milliseconds: r.args[0]),
  };
}
```

This `SampleService` can easily be used as a contract to implemented the `Worker`. The worker can then be used for
Dart Isolates as well as Web Workers.

```dart
class SampleWorker extends Worker implements SampleService {
  SampleWorker(dynamic entryPoint, {List args = const []})
      : super(entryPoint, args: args);

  @override
  Future io({required int milliseconds}) =>
      send(SampleService.ioCommand, [milliseconds]);

  @override
  Future cpu({required int milliseconds}) =>
      send(SampleService.cpuCommand, [milliseconds]);
}
```

Squadron 3 simplifies the implementation of platform worker's main program thanks to the `run()` function. This
function takes two arguments:
* first, a `WorkerService` initializer responsible for creating the service to be used by the platform worker.
* second, a `WorkerRequest` that will enable setting up the service; this argument is not used for Browser platform
but it is required in native scenarios where it must be set to the `Isolate`'s main program parameter.

* native implementation:

```dart
SampleWorker createVmSampleWorker() => SampleWorker(_main);

// Isolate entry-point.
// It must be a top level function or static method accepting a Map agrument.
// The argument passed to the entry-point must be passed to the run() function.
void _main(Map command) => run((startRequest) => SampleService(), command);
```

* browser implementation:

```dart
SampleWorker createJsSampleWorker() => SampleWorker('sample_worker_js.dart.js');

// Web Worker entry-point.
// It must be a parameter-less "main()" function.
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

Communication between threads does not come for free, and some experiments have found that using `jsonEncode()`
may actually be more efficient when sending large data sets (e.g. a `List` containing  many `Map`s) even
with the overhead of calling `jsonDecode()` on the receiving end. This is especially true on Web platforms
because Dart's implementation of [postMessage](https://api.dart.dev/stable/dart-html/MessagePort/postMessage.html)
involves converting Dart objects to native JavaScript objects. These objects will then be cloned by the
browser.

### <a name="channels_and_types"></a>Channels, Types, and Browser Platforms

To provide a cross-platform development experience, Squadron encapsulates `Isolates` and `Web Workers` as
well as the means to communicate between the main app's code and the code they execute. This is achieved
via the `Channel` class.

![Diagram about type flow through Squadron Channels](https://raw.githubusercontent.com/d-markey/squadron/main/channels_and_types.png)

`Channel` enables data exchange between threads and inherits the constraints of the target platforms,
in particular the type system. Dart Native platforms will typically be quite relaxed when communicating
between threads, even allowing custom Dart objects to come through.

**But JavaScript will not be so forgiving because JavaScript doesn't know about Dart types.**

To transfer a custom object, it must be serialized on the sender end and deserialized on the receiver end.
There are several ways of serializing a custom object, e.g. JSON structure holding the object's attributes,
or `String`/binary representation of the object...

However, when the data to be transfered hits the browser's Web Worker implementation, only basic type information
(number, boolean, string, array or map) is retained. In particular, generic types sent from one side will not
be received with the same generic type on the other end. For instance, when a sending a `List<String>` or a
`Map<String, dynamic>` to a service worker, browser platforms will provide the data to the worker service as
a bare `List` (= `List<dynamic>`) or a bare `Map` (= `Map<dynamic, dynamic>`). This is an important point to
ensure your app will happily run on browsers.

Serialization and deserialization should be done as close to the `Channel` as possible, typically when calling
the `send` method or when receiving data in the `operations` map.

For example, suppose we have the following service definition, processing `ServiceRequest` messages from callers
and replying with `ServiceResponse` objects:

```dart
abstract class ServiceDefinition {
   FutureOr<ServiceResponse> serviceMethod(ServiceRequest request);

   static const cmdServiceMethod = 1;
}

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
```

Then the approach below is a generic way to send/receive the `ServiceRequest`/`ServiceResponse` messages via
Squadron:

```dart
class ServiceImplementation implements ServiceDefinition {
   @override
   ServiceResponse serviceMethod(ServiceRequest request) {
      // process the request and produce the response
   }

   // in the operations map, deserialize argument and serialize result

   @override
   late final Map<int, CommandHandler> operations = {
      ServiceDefinition.cmdServiceMethod: (WorkerRequest r) =>
          serviceMethod(
            ServiceRequest.deserialize(r.args[0])   // deserialize ServiceRequest
          ).serialize();                            // serialize ServiceResponse
   };
}

class ServiceWorker extends Worker implements ServiceDefinition {

   // in the worker overrides, serialize argument and deserialize result

   @override
   ServiceResponse serviceMethod(ServiceRequest request) async =>
        ServiceResponse.deserialize(                // deserialize ServiceResponse
          await send(
            ServiceDefinition.cmdServiceMethod,
            [ request.serialize() ]                 // serialize ServiceRequest
          )
        );
}

class ServiceWorkerPool extends WorkerPool<ServiceWorker> implements ServiceDefinition {
  ServiceWorkerPool(dynamic entryPoint, ConcurrencySettings concurrencySettings)
      : super(() => ServiceWorker(entryPoint),
            concurrencySettings: concurrencySettings);

   // nothing to do in the service pool, the service worker and service implementation
   // take care of all serialization aspects

  @override
  Future<ServiceResponse> serviceMethod(ServiceRequest request) =>
      execute((w) => w.serviceMethod(request));
}
```

### <a name="json_annotation"></a>Note on `package:json_annotation`

Packages such as [json_annotation](https://pub.dev/packages/json_annotation) / [json_serializable](https://pub.dev/packages/json_serializable)
can be used to generate the serialization and deserialization code for custom classes. By default, objects will be
serialized to / deserialized from `Map<String, dynamic>` data structures.

In Browser scenarios, this will lead to errors as the `Map<String, dynamic>` structures lose their strong types
when they get processed by the browser.

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
    return get(key) != null;
  }

  @override
  void set(dynamic key, dynamic value, {Duration? timeToLive}) {
    // cache the value with the specified key and TTL
  }

  @override
  CacheStat getStats() {
    // return cache stats
  }

  // command IDs
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
  CacheWorker(dynamic entryPoint, {List args = const []})
      : super(entryPoint, args: args);

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

Note how `getStats()` implementations require serialization/deserialization of the `CacheStat` object. This is
necessary to cross platform worker boundaries. See [].

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

The following service is an example for a computation leveraging the shared cache. Its
constructor takes a `Cache` parameter.

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
  OtherWorker(dynamic entryPoint, {List args = const []})
      : super(entryPoint, args: args);

  @override
  Future<int> compute(int n) => send<int>(OtherService.computeCommand, [n]);

  // other proxy service methods...

  @override
  final Cache? _cache = null;
}
```

The platform worker assembles everything. It is essentially the same as above, with some extra initialization
code to set up a `CacheClient` and provide it to the `CacheService`.

To create a `CacheClient` from within the platform worker, the `CacheWorker`'s `Channel` must be somehow
passed to the `OtherWorker`. This is done using the `share()` and the `serialize()` methods provided by
`Channel`. These methods will return an opaque object that can be safely sent across workers and deserialized
to recreate a `Channel`, thereby bridging the gap between the `OtherService` instances and the `CacheService`
Singleton.

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
 +-------------------+        |           +----------------+   [4]
 |  main program     | --[1]--+    +----> | otherWorker #1 |    |
 |  ---------------- |             |      | -------------- |    |
[2] OtherWorker pool | --[3]--+    |      | cacheClient #1 | ---|
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

Starting with Squadron 3.3, the design for a shared cache could be based on a `LocalWorker` for the `CacheWorker`.
However if the cache is often used from workers, it would increase the load on the main thread's event loop and may
impact the user experience.

### <a name="local_worker"></a>Local Workers

Squadron 3.3 introduces `LocalWorker`, a `Woker`-like class running in the same thread as its owner. The main idea
behind `LocalWorker` is to enable executing code in the context of the owner thread such as a the main thread in a
Flutter app, thereby giving access to Flutter APIs. In this scenario, it is important to note that the `LocalWorker`
will use the event loop of the main app. As a result, if the load on the `LocalWorker` is high enough, it could impact
the responsiveness of the application.

The implementation of a `LocalWorker` follows the same principles as for a `Worker`. Start by implementing a
`WorkerService` with the logic you want to expose:

```dart
// The service interface
abstract class IdentityService implements WorkerService {
  FutureOr<String> whoAreYou();

  static const whoAreYouCommand = 1;
}

// The service implementation
class IdentityServiceImpl extends IdentityService {
  @override
  String whoAreYou() {
    return Squadron.id;
  }

  @override
  late final Map<int, CommandHandler> operations = {
    IdentityService.whoAreYouCommand: (req) => whoAreYou(),
  };
}
```

To allow other workers to communicate with the `LocalWorker`, a `LocalWorkerClient` must be implemented. The client
will be passed a `Channel` obtained from the `LocalWorker`, and simply forwards commands to the `LocalWorker`.

```dart
// The service client: this class will be used in workers that need to call the service implementation
class IdentityClient extends LocalWorkerClient implements IdentityService {
  IdentityClient(Channel channel) : super(channel);

  @override
  Future<String> whoAreYou() =>
      send(IdentityService.whoAreYouCommand, []);
}
```

Next, we have the code for the real `Worker` that will be using the `LocalWorker`. Typically, it is based on a
`WorkerService`, for instance:

```dart
abstract class MyWorkerService {
  FutureOr<String> whoAreYouTalkingTo();

  static const whoAreYouTalkingToCommand = 1;
}

class MyWorkerServiceImpl implements MyWorkerService, WorkerService {
  MyWorkerServiceImpl(this._identityClient);

  final IdentityClient _identityClient;

  @override
  Future<String> whoAreYouTalkingTo() async {
    // this is where the local worker is called
    final localWorkerIdentity = await _identityClient.whoAreYou();
    return 'I am ${Squadron.id}, and I am talking to $localWorkerIdentity.';
  }

  @override
  late final Map<int, CommandHandler> operations = {
    MyWorkerService.whoAreYouTalkingToCommand: (WorkerRequest r) => whoAreYouTalkingTo()
  };
}

class MyWorker extends Worker implements MyWorkerService {
  MyWorker(dynamic entryPoint, {, List args = const []})
      : super(entryPoint, args: args);

  @override
  Future<String> whoAreYouTalkingTo() =>
      send(MyWorkerService.whoAreYouTalkingToCommand, []);
}
```

The code to fire up the workers in browser and VM worlds need to get the `Channel` from the `LocalWorker`,
so we will pass the local worker to the functions that instantiate `MyWorker`. The channel is obtained by
calling the `share()` method then passed on to `MyWorker` via the `args` parameter where it must be serialized
to cross platform thread boundaries. This array will be received by the platform worker thread at startup via
the `startRequest` argument:

* VM:

```dart
MyWorker createMyWorker(LocalWorker<IdentityService> identityServer) {
  return MyWorker(_start, args: [identityServer.channel?.share().serialize()]);
}

void _start(Map command) => run((startRequest) {
      // startRequest.args[0] contains the channel shared from the local worker
      final channel = Channel.deserialize(startRequest.args[0])!;
      final identityClient = IdentityClient(channel);
      return MyWorkerServiceImpl(identityClient);
    }, command);
```

* Browser:

```dart
MyWorker createMyWorker(LocalWorker<SizeService> identityServer) {
  return MyWorker('/my_worker.dart.js', args: [identityServer.channel?.share().serialize()]);
}

void main() => run((startRequest) {
      // startRequest.args[0] contains the channel shared from the local worker
      final channel = Channel.deserialize(startRequest.args[0])!;
      final identityClient = IdentityClient(channel);
      return MyWorkerServiceImpl(identityClient);
    });
```

And that's it! The final step is to bind everything together, for instance in the main program:

```dart
void main() {
  Squadron.setId('main');

  final identityServer = LocalWorker<IdentityService>.create(IdentityServiceImpl());

  print(identityServer.whoAreYou());

  try {
    final worker = createMyWorker(identityServer);
    print(await worker.whoAreYouTalkingTo());
  } finally {
    identityServer.stop();
  }
}
```

Note: the `LocalWorker` must be stopped to stop the program.

```
Architecture Diagram

                                  +----------------+
                             +--> | MyWorker       |
                             |    | -------------- |
                             |    | identityClient | --+
 +------------------+        |    +----------------+   |
 |  main program    | --[2]--+                        [3]
 |  --------------- |                                  |
[1] identityServer  | <--------------------------------+
 +------------------+ 

1: the main program first creates a LocalWorker<IdentityService>
2: the main program spawns a MyWorker, providing it with the LocalWorker<IdentityService> it has just created
3: MyWorker will call into the LocalWorker running in the main thread via its LocalWorkerClient
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

## <a name="logging"></a>Logging & Debug Mode

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
  Squadron.logLevel = SquadronLogLevel.warning;
  Squadron.logger = DevSquadronLogger();
  // ... and then the rest of your code
}
```

When your app fires up a worker, the log level will be passed on to the platform worker automatically. Squadron
4.x also automatically supports logging in workers and there is no need to initialize a logger in worker code.
Log messages from workers will be sent to the main thread (depending on the worker's log level) which facilitates
logging form workers in Web apps. Please note that logging impacts performance as messages must be transferred
from the worker thread to the main thread.

Additionally, Squadron 4.x provides a `debug` log level which is even finer than the `finest` log level. Used
in combination with `Squadron.debugMode = true`, this log level allows for displaying log messages even though
the current log level is above `debug`.

Also, when `Squadron.debugMode` is set to `true`, the `travelTime` property of `WorkerRequest` and `WorkerResponse`
will contain the time elapsed between the moment the message was serialized (on the emitting end) and deserialized
(on the receiving end). This duration is expressed in microseconds and includes the time it took to transfer the
message from one thread to another, as well as the delay due to the receiving thread's event loop (the message may
have to wait before it is picked up by the event loop) and the delay to deliver the message when using a pool of
workers (the message may have to wait for a worker to become available).

## <a name="prod"></a>Releasing Your App

Releasing your application for Dart Native platforms should be straightforward.

To release the Browser version, the worker code must first be compiled to JavaScript:

```
dart compile js -o lib/src/browser/service_worker.dart web/service_worker.dart.js
```

Flutter's Web runtime includes a service worker called `flutter_service_worker.js`: make sure you use
a different name for your workers to avoid any conflict! After compiling your worker scripts, you can
build your app using:

```
flutter build web
```

## <a name="thanks"></a>Thanks!

* [SwissCheese5](https://github.com/SwissCheese5) for his patience and feedback when implementing
Squadron into his Flutter application.
* [martin-robert-fink](https://github.com/martin-robert-fink) for the feedback on Squadron's
`Stream` implementation -- this has resulted in huge progress and a major improvement!
