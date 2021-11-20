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
- See examples on how to scaffold Services, Squadron Workers and platform workers.
- Added tests for Web Workers (run with "dart run build_runner serve -r" and point your browser to http://localhost:8080/index.html).

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
