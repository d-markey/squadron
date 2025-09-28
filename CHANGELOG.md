## 7.2.0

- Support sending Dart `DateTime` / JS `Date` instances to/from Workers.
- Fix warnings from [pub.dev](https://pub.dev/packages/squadron/score).

## 7.1.2+1

- Fix warnings from [pub.dev](https://pub.dev/packages/squadron/score).

## 7.1.2

- Expose the count of active connections via the worker's stats.
- Added tests from https://github.com/d-markey/squadron/pull/71 to check for memory leaks. Credits go to https://github.com/jpohhhh, thanks!
- Properly close `ForwardStreamController` on VM to avoid memory leaks -- fixes https://github.com/d-markey/squadron/issues/70.

## 7.1.1

- Be less aggressive on task scheduling in Worker pools. When synchronously submitting many tasks to the pool, the `_schedule` synchronous method was systematically called and would block the event loop. This version uses a timer to avoid flooding the pool's scheduler.

## 7.1.0

- Move stats management out of Worker into a specialized class.
- Breaking change: removed `WorkerStat.status`.
- Remove accessors to `ConcurrencySettings` properties in `WorkerPool`.
- Update tests.

## 7.0.0

- Implement serialization contexts to ser-/deser-ialize while retaining object identities. For instance, when calling a service method `myServiceMethod(x, x)`, previous versions of Squadron would serialize `x` twice, resuling in two different instances on the receiving end. Using `ContextAwareConverter`, `x` can be serialized only once and the same serialized representation of `x` would be used for the second argument. Note that this also supports serialization of graph of objects, including those with cyclical references.
- Local services can now be plain Dart classes -- squadron_builder will take care of generating the operations map. No need de derive from `WorkerService` anymore.
- New annotation for squadron_builder: `SquadronService.local()` to indicate the service may run as a local service; `localWorker` to be applied on parameters used to pass a local service on to a worker (only supported for start requests); `withContext` parameter to `SquadronMethod` to force use of a marshaling context when ser-/deser-ializing to/from that service method.

## 6.2.0

- Implement `jsify`/`dartify`-like functions to handle conversion between Dart / JavaScript. The implementation supports arbitrary `Map`s, `List`s and `Set`s, as well as `BigInt`s.
- When converting a message to JS, the list of transferable objects is populated at the same time if required.
- Reworked tests & activate Wasm tests.
- Reworked test Web console (CSS by ChatGPT).

## 6.1.6

- Fix `IWorker.terminate()` to make sure worker termination is really immediate.

## 6.1.5

- Fix a bug where streaming operations in workers are not cancelled if the worker has been stopped before the subscription is cancelled.
- Update unit tests.
- Update examples.

## 6.1.4

- Add `IWorker.terminate()` to enable immediate termination of workers and worker pools.
- Refactor tests + browser test console + add unit tests for thread termination.

## 6.1.3

- Handle weird case where `int` is received as `JSString` when worker was compiled to Web Assembly. Fixes https://github.com/d-markey/squadron_builder/issues/23.

## 6.1.2

- Remove `DirectCastConverter` and use `CastConverter` instead. Fixes https://github.com/d-markey/squadron_builder/issues/22.
- Remove method `Converter.td<T>()` for handling typed data. Instead, conversion should be based on `TypedDataMarshaler<T>`, combined with `Squadron.converter` when necessary (eg. when the typed data list is nested in a map / list).

## 6.1.1

- `Squadron.converter` should be modifiable but it was declared `final`: implement getter and setter.
- Interested artefacts can register callbacks with `Squadron.onConverterChanged()` to be notified after the converter has been updated.

## 6.1.0

- Implement specific marshaler for `TypedData` (used by `squadron_builder` >= 6.1.0). 

## 6.0.4

- Breaking change: the connection channel is provided to caller before the service is installed (when the service is mixed in with `ServiceInstaller`); if service installation fails, the channel is closed and the caller is notified with an error and an `endOfStream` response.
- Change `token` type to `CancelationToken` in `LocalWorkerClient.send()`.
- Add support for annotating service classes to be used as local workers.

## 6.0.3

- Use `DirectCastConverter` on native platforms.

## 6.0.2

- Update documentation.

## 6.0.1

- Fix wasm compatibility issues reported by pub.dev.

## 6.0.0

- /!\ BREAKING CHANGES /!\
- Merged `worker_monitor` into `worker_runner`.
- Removed `SerializeWith` annotation.
- Removed custom cancelation token implementations and switched to `package:cancelation_token`.
- Removed custom logger implementations and switched to `package:logger` for logging.
- Reworked the Squadron singleton.
- Worker methods `send()` and `stream()` are no longer generic: they return `Future<dynamic>` and `Stream<dynamic>`. It is now the user responsibility to ensure service arguments and return values are properly handled in terms of Dart type. One major caveat comes from Web Assembly, where Dart `int` values sent from one side are received as Dart `double` values on the other side. To help with conversions, Squadron provides converters and selects the proper converter depending on the runtime platform, so you can "cast" values on either side of the service call (see `Squadron.converters` in `squadron_singleton.dart`). The recommendation is to use [squadron_builder](https://pub.dev/packages/squadron_builder) to generate the code for your workers -- it will take care of casting and marshaling.
- Reworked unit tests, and made unit tests cover VM, JS/JS and JS/Wasm scenarios. Wasm/JS and Wasm/Wasm are not unit tested yet.
- Published the [test console](https://d-markey.github.io/squadron/browser-tests/) to enable testing of all combinations.
- Also published the [test coverage](https://d-markey.github.io/squadron/coverage/) report.

## 5.1.6

- Reworked exception deserializer management to protect from multiple registrations and allow for deregistration. See https://github.com/d-markey/squadron/issues/27#issuecomment-1717452323.
- Added support for installable/uninstallable worker services. If a service needs to take action after the worker thread has started or before it is stopped, it should extend or implement `ServiceInstaller` and provide one or both of `install()` / `uninstall()`. These methods will be called on platform thread setup/teardown. See https://github.com/d-markey/squadron/issues/29#issuecomment-1719682340.

## 5.1.5

- Removed `stdout_logger.dart` because it imports `dart:io` which made pub.dev revoke the support for Web platforms.

## 5.1.4

- BREAKING CHANGE: Removed `squadron_service.dart`, `squadron_worker.dart` and `squadron_local_worker.dart` libraries: import only `squadron.dart` instead.
- Added check to verify Web worker entry point exists upon error.
- Reorganized source code.
- Added topics and funding to pubspec.

## 5.1.3

- Add unit test raising a 'Null check operator used on a null value' exception when cancelling a streaming service method + stopping the worker.
- Fix 'Null check operator used on a null value' exception when cancelling a streaming service method + stopping the worker.

## 5.1.2

- Fix 'marshal' typo -- provide a compatibility layer to mark as deprecated all versions using '*marshall*' and mark these artefacts as deprecated. They will eventually be removed.
- `PlatformWorkerHook` and `EntryPoint` aliases now return `FutureOr<void>`.

## 5.1.1

- Use `DateTime.now().toUtc()` instead of `DartTime.timestamp()` which is available starting from Dart 3 only. Fixes https://github.com/d-markey/squadron/issues/22.

## 5.1.0

- Make `WorkerRequest` and `WorkerResponse` aliases of `List` to minimize serialization overhead. Replace previous `WorkerRequest` and `WorkerResponse` implementations with extension methods. This may be a breaking change.
- Add `EntryPoint` and `PlatformWorker` typedefs to enforce type safety across runtime platforms. `EntryPoint` and `PlatformWorker` should both resolve to `dynamic` in the IDE. At compile time, they should resolve to the concrete types according to the platform (ie. `String` and `Worker` from `dart:html` for Web platforms, `FutureOr<void> Function(List)` and `Isolate` on native platforms). This should help prevent issues such as https://github.com/d-markey/squadron/issues/17.
- Provide access to platform worker instance upon initialization. See https://github.com/d-markey/squadron/issues/20.

## 5.0.0

- Enable support of Dart 3. 
- Breaking change: use `List` instead of `Map` for serialization of worker request/response.

## 4.3.8

- Downgrade `meta` version to `^1.8.0` to match `flutter_test` requirements (fix for https://github.com/d-markey/squadron/issues/18).

## 4.3.7

- Ensure uniqueness of cancellation token IDs across workers (breaking change for classes implementing/deriving from `CancellationToken`: `id` is now a `String`).

## 4.3.6

- Downgrade `meta` version to `^1.8.0` to match `flutter_test` requirements.
- Fix pool scheduler algorithm to ensure worker availability before dispatching tasks.

## 4.3.5

- Add `UseLogger` annotation to have package [squadron_builder](https://pub.dev/packages/squadron_builder) generate the associated code in worker threads.

## 4.3.4

- Add notifications when a worker is added or removed. Interested components can register listeners (callbacks) for these notifications.
- Disable automatic log-forwarding between workers and their parents. It is possible to restore this behaviour manually by using [ParentSquadronLogger] as a logger during initialization of the platform worker.
- Split logging logic between message formatting vs. emitting.

## 4.3.3

- Rename `SquadronSerializer` to `SquadronMarshaller`.
- Update dev dependencies.

## 4.3.2

- `WorkerResponse`: if `result` is an `Iterable` but not a `List`, call `toList()` to get results before serializing the response back to the caller.
- `SerializeWith`: annotation used to indicate how to marshal data to/from a service running in a Worker. See also `SquadronSerializer` class.

## 4.3.1

- `CancellationToken`: provide `Future<bool> isCancelled({bool throwIfCancelled = false})` to make it easier to check cancellation token status in worker services.

## 4.3.0

- `ValueWrapper`: check future hasn't already completed before calling `complete()` or `completeError()`.

## 4.2.0

- Add `baseUrl` parameter to `SquadronService` annotation.

## 4.1.0

- Now with annotations to support code generation. To be used with package `squadron-builder`.

## 4.0.0

- **Breaking changes**: all deprecated artefacts have been removed.
- **Breaking change**: `LocalSquadronLogger` has been deleted.
- **Breaking change**: the `args` and `token` arguments of methods `send()` and `stream()` are now named argument.
- **Breaking change**: removed the optional `id` parameter that was passed to `Worker` constructors.
- **Breaking change**: disabled message inspection for Web channels. In previous versions, Squadron would inspect each piece of data exchanged via `_JsChannel`s to identify objects whose ownership must be transfered to the receiving end (the `transfer` argument in [`postMessage`](https://developer.mozilla.org/en-US/docs/Web/API/Worker/postMessage)). However most of the time, the request / response objects are usually made of `List`, `Map`, and base types, all of which can cross thread boundaries "as-is". This behavior is now controlled by optional parameters `inspectRequest` and `inspectResponse` of methods `Worker.execute()` and `Worker.stream()`, defaulting to `false` thus disabling message inspection. Passing `true` will activate message inspection for request and/or response and will be necessary when the message contains an object whose ownership must be transfered to the receiving end, typicaly a [`MessagePort`](https://api.dart.dev/stable/dart-html/MessagePort-class.html). Basic testing found message transfer time improvement around ~5-10% for large payloads, e.g. a `List` containing many `Map` items (note that in Web scenarios, JSON serialization could prove a more efficient alternative). It should have little to no effect on smaller messages. Start requests will always be processed with `inspectRequest = true` and `inspectResponse = true`.
- Fixed issue with workers on native platforms: ensure all `ReceivePorts` are closed upon `Isolate` termination.
- Support logging accross workers (which made `LocalSquadronLogger` obsolete).
- Added support to reset the Squadron singleton.
- Reworked examples & unit tests.

## 3.4.0

- Rewritten streaming implementations (fix for https://github.com/d-markey/squadron/issues/8).
- Added unit tests.

## 3.3.2

- Implemented a `LocalLogger` to have Web workers log messages from the main window (effectively logging via Dart debugger if present).
- Removed import of `dart:isolate` from `_worker_runner.dart`.
- Made `coverage` a dev dependency.
- Added a tool to extract coverage metrics during Github Dart workflow.
- Updates badges to include coverage metrics and platform info.

## 3.3.1

- Fixed streaming from `LocalWorker`.
- Added tests for `LocalWorker`.
- Improved cancellation handling.
- Added tests to improve test coverage.

## 3.3.0

- Implemented `LocalWorker`, a worker-like class living in the same thread as its owner and available for inter-worker messaging. For instance, in a Flutter app, instantiating a `LocalWorker` in the main thread enables other workers to (indirectly) call Flutter APIs that are otherwise not available in the context of a secondary thread.
- `LocalWorker` uses the same concepts and approach as `Workers`, such as the `operations` map and the `WorkerService` interface.

## 3.2.2

- Document types and release mode (special thanks to [SwissCheese5](https://github.com/SwissCheese5)).
- More error handling at communication points.
- Use lower log levels for internal Squadron log messages.
- Added test coverage.

## 3.2.1

- Document the new logging feature.
- Make `sendRequest()` async in browser `Channel` (implementation closer to that of native `Channel`).
- Add a timestamp to pool workers to record the time when it was assigned its last task.
- Sort pool workers to distribute tasks to those that have the largest capacity and the oldest timestamp.
- Add command property to `WorkerException`.
- Reorganized the test folder.
- Recompiled test Web workers.

## 3.2.0

- Added a logging mechanism to facilitate debugging Squadron's internals.
- Reworked connection flow between main program and worker.
- Reworked task scheduling.
- Fixed issue https://github.com/d-markey/squadron/issues/3.
- Added tests for logging and workers failing to initialize.

## 3.1.4

- Implemented cancellation token to enable worker task notification that cancellation has occured.
- Implemented `TimeOutToken`, `CancellableToken` and `CompositeToken`.
- Updated `README.md`.
- Added unit tests.

## 3.1.0

- Several minor changes (some possibly breaking changes but easy to fix).
- Split library into `squadron_service.dart` (worker services only), `squadron_worker.dart` (worker services and workers without pool) vs. `squadron.dart` (worker services, workers and pools).
- Split `Channel` into `Channel` (used to send a `WorkerRequest`) and `WorkerChannel` (used to send a `WorkerResponse`).
- Added `ConcurrencySettings` to eventually replace `minWorkers`, `maxWorkers` and `maxParallel`.
- Added `WorkerPool.execute()` (will eventually replace `WorkerPool.compute()`).
- Added `WorkerPool.scheduleTask()` to schedule a `ValueTask`. Result will be accessible from future `ValueTask.value`.
- Added `WorkerPool.scheduleStream()` to schedule a `StreamTask`. Results will be accessible from stream `StreamTask.stream`.
- `ValueTask` and `StreamTask` provide information on task execution (eg. status, wait time, execution time...).
- Added `WorkerPool.cancel()` to support worker task cancellation.
- Updated `README.md`.
- Added unit tests.

## 3.0.0

- Split library into `squadron_service.dart` (worker services only), `squadron.dart` (worker services and workers without pool) vs. `squadron_pool.dart` (worker services, workers and pools).
- Moved `connect()` and `process()` from Worker to WorkerService.
- Provided the `run()` function to facilitate implementation of platform workers.
- Adapted tests and examples.
- Updated `README.md`.

## 2.0.2

- Single test code base for both platforms.
- Added BitCoin service to test live network access from workers (courtesy of coindesk.com).
- Added PiDigits service (related to https://github.com/d-markey/squadron/issues/1).
- Retaining attempts based on manually operating a browser to run tests in /web (different test code base) and /test/browser-tests (same test code base).

## 2.0.1

- Remove dependency on js package.

## 2.0.0

- This version supports workers running in Isolates as well as Web Workers.
- Platform implementations are now more straightforward thanks to `Worker.connect()` and `Worker.process()`.
- See examples on how to scaffold services, Squadron Workers and platform workers.
- Added tests for Web Workers (run with `dart run build_runner serve -r` and point your browser to http://localhost:8080/index.html).

## 1.0.2

- Added support for minimum count of workers in pool.
- Make sure Isolate is killed when the worker is stopped.
- Keep track of stats from stopped workers.
- Update tests & examples (proper error handling, command map, worker monitoring).

## 1.0.1

- Improve error handling.
- Improve documentation.
- Add unit tests.

## 1.0.0

- Initial version.
