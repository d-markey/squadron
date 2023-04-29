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
