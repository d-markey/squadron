# Squadron AI Agent Guide

This document provides essential technical context for AI agents working on the Squadron library.

## Project Essence
Squadron is a multi-threading library for Dart and Flutter. It provides a unified API to run code in background workers across all supported Dart platforms.

## Core Architecture
- **Worker**: The base class for client-side proxies that wrap background service logic.
- **WorkerPool**: Manages a collection of workers to distribute high-load tasks.
- **WorkerService**: The interface defining what the worker can do.
- **Channel**: The communication layer. Platform-specific implementations handle Isolate ports (Native) or MessagePorts (Web).
- **WorkerRequest / WorkerResponse**: Extension types wrapping `List` data for efficient, Zero-copy-like communication (on VM) and low-overhead on all platforms.

## Platform Implementation Nuances
- **Conditional Imports**: Look for `_impl` directories. Logic is often split into `native`, `web`, and `xplat` (cross-platform).
- **Web Workers**: Unlike VM isolates, Web Workers are loaded from standalone `.js` or `.wasm` files.
- **JS Interop Patch**: The file `_impl/web/_patch.dart` provides custom `$jsify` and `$dartify` functions. These **MUST** be used instead of the standard `dartify`/`jsify` from `package:web` or `dart:js_interop` as they:
    - Handle complex objects (Maps, Sets) recursively.
    - Support `BigInt` and `DateTime` objects.
    - Automatically identify and manage **Transferable Objects** (like `JSArrayBuffer`) for Zero-copy-like performance in Web Workers.

## File Naming & Exposure
- **Private Files**: Files starting with an underscore `_` (e.g., `_worker_task.dart`) are considered private to the package.
- **Exposure**: These files **MUST NOT** be exported in any public API (such as `lib/squadron.dart`). They are strictly for internal library use.
- **Internal Extensions**: Some extensions provide internal-only functionality for public classes (e.g., `CancelationTokenExt` on `WorkerRequest`). These extensions:
    - **MUST** be decorated with `@internal`.
    - **MUST** be hidden from the public API using the `hide` keyword in the main export file (`lib/squadron.dart`).

## Performance Principles
- **Microtask Scheduling**: Dart's event loop is sensitive to future chaining. Every `await`, `Completer.complete()`, or `Future.then()` adds at least one microtask hop.
- **Optimization Strategy**: Always aim to minimize the number of links in the Future chain. Avoid `async`/`await` in performance-critical paths (e.g. `Worker.send`) by returning the `Future` directly. Only use `Completer` or `ForwardCompleter` when asynchronous coordination, such as cancellation notification or worker startup, is strictly required.
- **Stat Synchronicity**: Update statistics (like `beginWork`/`endWork`) synchronously relative to the request lifecycle to ensure state consistency for callers.

## Testing & Verification (CRITICAL)
- **Recompilation**: Any change to code that is **imported by the worker binaries** requires recompilation of the test artifacts in `test/workers/`. 
    - **Triggers**: Changes to `WorkerService`, `Channel`, `WorkerRequest`, `WorkerResponse`, and **any logic in `_impl/`** that is used by workers (even platform-specific web/native implementations).
    - **No Recompile Needed**: Changes to client-side orchestration like the `Worker` class proxy, `WorkerPool`, or startup logic.
- **Canonical Test Command**: Use `.\tool\run_tests.bat /b`.
    - The `/b` flag triggers `tool/compile_tests.dart` which generates the `.js` and `.wasm` files required for web tests.
    - **NEVER** rely solely on `dart test` after modifying core library code, as it will run web tests against stale worker binaries.
- **Sequential Execution**: Tests are run with `-j 1` to avoid race conditions and resource exhaustion during worker process spawning.

## Cancellation Logic
- **CancellationToken**: Based on the `cancelation_token` package.
- **SquadronCancelationToken**: A specialized wrapper that enables cancellation to be signaled across thread/worker boundaries via the `Channel`.

## Error Handling & Logging
- **SquadronException**: All errors crossing the worker boundary are wrapped in this class (or its subclasses). It carries the original message and a stringified stack trace.
- **ExceptionManager**: Used by `Channel` to serialize/deserialize exceptions consistently across platforms.
- **Logging Propagation**: `WorkerResponse` can carry `LogEvent` objects (from package `logger`). When received, the client-side `Channel` automatically re-emits them through its own `logger`.

## Communication Patterns
- **Single-value (Future)**: A simple request-response cycle. One `WorkerRequest` results in exactly one `WorkerResponse`.
- **Streaming (Stream)**: A single `WorkerRequest` triggers multiple `WorkerResponse` messages. The stream is concluded by a special `WorkerResponse.closeStream` message (where `endOfStream` is `true`).
- **In-place Serialization**: To minimize allocations, `WorkerRequest` and `WorkerResponse` use `wrapInPlace()` and `unwrapInPlace()` to modify their underlying `List` data before/after crossing the communication channel.

## Troubleshooting
- **Flaky Tests**: Often due to not using `run_tests.bat` or resource contention on the test machine.
- **Mismatched Behavior**: Check if the change was applied to `xplat` but needs specialized handling in `native` or `web`.
