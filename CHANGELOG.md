## 4.0.0

- Breaking changes : deprecated stuff have been removed.
- Added option to skip message inspection for Web channels. By default, Squadron inspects each piece of data exchanged via `_JsChannel`s to identify objects whose ownership must be transfered to the receiving end (the `transfer` argument in [postMessage](https://developer.mozilla.org/en-US/docs/Web/API/Worker/postMessage)). However most of the time, the request / response objects are usually made of base types + `List` + `Map` which can cross thread boundaries "as-is", making the inspection step mostly useless. By setting `inspectRequest` and/or `inspectResponse` to `false` when calling `Worker.execute()` and `Worker.stream()`, the inspection step is skipped and benchmarks show an improvement ~5-10% in terms of throughput for Web workers.
- Reworked unit tests.

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
