---
name: squadron-cancelation
description: Use when implementing task cancelation, handling CancelationToken, propagating cancelation signals across thread/worker boundaries, and dealing with synchronous vs. asynchronous cancelation in Squadron.
---

# Squadron Task Cancelation Guide

Squadron supports propagating task cancelation across thread boundaries (isolates on Native, Web Workers on Web) using the `cancelation_token` package.

*Note on Spelling:* Following the `cancelation_token` package convention, Squadron uses **`CancelationToken`** with a single **'l'**.

## 1. Cooperative Cancelation with `CancelationToken` (Recommended Approach)
The standard, most robust way to handle task cancelation in Squadron is using a `CancelationToken`. If your worker method needs to coordinate cancelation from inside the worker thread itself, accept a single, optional `CancelationToken` parameter in your annotated method:

```dart
@SquadronMethod()
Future<String> computeLongTask(int iterations, [CancelationToken? token]) async {
  for (int i = 0; i < iterations; i++) {
    // 1. Periodically check if cancelation was requested
    token?.throwIfCanceled();

    // Do work...
    await Future.delayed(Duration(milliseconds: 100));
  }
  return 'Completed';
}
```

- **Client-Side Trigger**: When the main thread cancels the token (`token.cancel()`), Squadron automatically notifies the background worker that the task was canceled.
- **Worker-Side Responsibility**: It is the explicit responsibility of the task implementation to periodically check the token (e.g., via `token?.throwIfCanceled()` or checking `token?.isCanceled == true`) and abort execution when necessary.
- **Dropping Results**: Once canceled, the future awaiting the worker's result on the main thread is resolved with a `CanceledException` (or `TaskCanceledException`), and any eventual results produced by the worker are dropped.

## 2. Synchronous vs. Asynchronous Task Cancelation
It is crucial to understand how execution flow affects cancelation handling:

- **Asynchronous Methods (`async`)**: The worker thread can yield control back to the event loop, allowing Squadron to receive the cancelation notification immediately and throw/abort during periodic checks.
- **Synchronous Methods (`FutureOr<>` with no `async` body / heavy blocking work)**: 
  - The task **cannot be truly interrupted** midway.
  - On the main thread, the future awaiting the worker's result will still appear canceled (resolving with a `CanceledException`) immediately when the token is canceled.
  - However, on the worker thread, the heavy synchronous computation monopolizes the event loop, meaning the cancelation notification cannot be processed or handled until the synchronous execution fully terminates.

## 3. Alternative: Task Cancelation via Captured Tasks (`ValueTask`)
You can also cancel tasks without explicitly passing a `CancelationToken` by capturing the returned `ValueTask` handle from a worker pool instead of awaiting the invocation immediately:

```dart
// 1. Capture the task handle from a worker pool instead of awaiting directly
final task = workerPool.computeLongTask(100);

// 2. Cancel the task later if needed
task.cancel('User aborted task');

try {
  final result = await task.value;
} on CanceledException catch (ex) {
  // Handles cancelation
}
```

## 4. Canceling via Worker Pools (`pool.cancel` / `pool.cancelAll`)
When working with `WorkerPool`, you can manage and cancel tasks directly at the pool level:
- **`pool.cancel(task, [String? message])`**: Cancels a specific captured task.
- **`pool.cancelAll([String? message])`**: Cancels all active and queued tasks across the worker pool.
