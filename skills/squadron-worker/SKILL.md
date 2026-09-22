---
name: squadron-worker
description: Use when building, writing, or refactoring Squadron workers, worker pools, worker services, or using squadron_builder annotations (@SquadronService, @SquadronMethod) for cross-platform multithreading in Dart and Flutter.
---

# Squadron & squadron_builder Developer Guide

Squadron is a multi-threading library for Dart and Flutter providing a unified Actor-pattern API for running background tasks across Native platforms (isolates) and the Web (web workers).

## 1. Setup & Dependencies
To use Squadron and code generation (`squadron_builder`), configure your `pubspec.yaml`:
- **Standard dependency**: `squadron`
- **Dev dependency**: `squadron_builder` and `build_runner`

## 2. Authoring a Service (`@SquadronService`)
Create your business service class in a dedicated file (e.g., `my_service.dart`).
- Decorate the class with `@SquadronService()`.
- Decorate worker methods with `@SquadronMethod()`.
- Worker methods **must** return `Future<...>` or `FutureOr<...>`.

### Example Service Implementation (`my_service.dart`):
```dart
import 'dart:async';
import 'package:squadron/squadron.dart';

part 'my_service.worker.g.dart';
import 'my_service.activator.g.dart';

@SquadronService(targetPlatform: TargetPlatform.all)
class MyService {
  @SquadronMethod()
  Future<String?> computeSomething(String? input, int count) async {
    if (input == null) return null;
    return 'Result: $input ($count)';
  }
}
```

## 3. Required Parts, Imports & Generated Artifacts
Every service file must declare a part and an import for the generated files:
1. `part 'my_service.worker.g.dart';`: included as a part, this file contains multithreading-aware versions of your service (`MyServiceWorker` and `MyServiceWorkerPool`) that handle client-side proxying, request dispatching, and worker lifecycle management.
2. `import 'my_service.activator.g.dart';`: imported, this file contains the worker's entry point plumbing required to initialize and run the service inside a background thread (Isolate or Web Worker).

## 4. Code Generation Command
To generate or update the `.worker.g.dart` and `.activator.g.dart` files after modifying your annotated services, run `build_runner` via the Dart CLI:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 5. Service Invocation & Interchangeability
When consumers want to use your service, they simply **import `my_service.dart`**. 
Because of the generated `.worker.g.dart` part file, importing `my_service.dart` exposes all three implementations:
1. **`MyService`**: The synchronous/local implementation (running on the main thread).
2. **`MyServiceWorker`**: The background worker proxy running tasks in a single background thread (Isolate/Web Worker).
3. **`MyServiceWorkerPool`**: A worker pool distributing tasks across multiple background workers.

Because `MyServiceWorker` and `MyServiceWorkerPool` both implement `MyService`, **all three classes can be used interchangeably** behind the `MyService` interface. This allows you to easily switch between running code synchronously on the main thread, asynchronously in a single worker, or scaled across a worker pool without changing consumer calling code.

## 6. Worker Pool Sizing & Concurrency Settings
When using `MyServiceWorkerPool`, proper sizing is crucial for performance and resource utilization. You configure concurrency settings via `ConcurrencySettings`:

### Key Pool Sizing Parameters:
- **`minWorkers`**: The minimum number of workers kept alive in the pool.
- **`maxWorkers`**: The maximum number of concurrent workers allowed.
- **`maxConcurrency`**: The maximum number of simultaneous tasks a single worker can handle before the pool spins up an additional worker (up to `maxWorkers`).
- **`idleTimeout`**: Duration after which idle workers are terminated to free up resources.

### Example Pool Instantiation:
```dart
final pool = MyServiceWorkerPool(
  // Provide your worker entrypoint function
  activator,
  concurrencySettings: ConcurrencySettings(
    minWorkers: 2,
    maxWorkers: 4,
    maxConcurrency: 2,
    idleTimeout: Duration(seconds: 30),
  ),
);
```

### Sizing Best Practices:
- **CPU-bound tasks**: Set `maxWorkers` close to the number of available hardware CPU cores (e.g., `Platform.numberOfProcessors`) to prevent context-switching overhead.
- **I/O-bound tasks**: You can set `maxWorkers` higher than the core count if workers spend most of their time waiting on network or disk I/O.
- **`maxConcurrency` tuning**: Increase `maxConcurrency` if your worker tasks are lightweight or asynchronous, allowing a single worker isolate/web worker to multiplex multiple requests efficiently without spawning extra threads.

## 7. Worker Lifecycle Management
- **Startup (`start()`)**: 
  - `worker.start()` (and pool initialization) is **automatically invoked** by Squadron on the very first worker call (lazy initialization).
  - However, you can call `worker.start()` explicitly upfront during application or feature initialization to avoid latency on the first method invocation.
- **Shutdown (`stop()`)**: 
  - `worker.stop()` (or terminating the `WorkerPool` via `pool.stop()`) **must always be called** when the worker is no longer needed.
  - **Crucial**: Failure to call `stop()` leaves an active communication stream/port open between the main thread and the worker thread. This background connection prevents the Dart VM event loop from draining, causing the program to **never terminate**.

## 8. Arguments & Return Types (Serialization & Base Types)
- **Recommended Types**: Stick to base types and collections for arguments and return values:
  - Primitives: `int`, `double`, `String`, `bool`, and `null` (along with their nullable variants, e.g., `int?`, `String?`).
  - Collections: `List<BaseType?>?` and `Map<BaseType, BaseType?>?`.
- Squadron automatically handles serialization across the main thread and worker thread boundaries for these types and `null`.
- **Custom Classes**: Passing custom objects requires special handling for cross-platform compatibility (native VM isolates have minimal constraints, but the Web platform only supports transferable objects / primitive serialization). For custom objects and serialization details, refer to the marshaling skill.
