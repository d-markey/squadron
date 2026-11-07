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
    // 1. Periodically check if cancellation was requested
    //    works because the loop body eventually yields
    token?.throwIfCanceled();
    //    alternatively, use `refreshAndThrowIfCanceled` instead
    // await token?.refreshAndThrowIfCanceled();

    // Do (asynchronous) work...
    await Future.delayed(Duration(milliseconds: 100));
  }
  return 'Completed';
}

@SquadronMethod()
FutureOr<String> computeLongSyncTask(int iterations, [CancelationToken? token]) {
  for (int i = 0; i < iterations; i++) {
    // 1. Periodically check if cancellation was requested
    //    Only detects cancellation already delivered; a new signal cannot
    //    arrive while synchronous code blocks the worker's event loop.
    token?.throwIfCanceled();
    //    this construct won't help because it is not allowed in a sync body
    // await token?.refreshAndThrowIfCanceled();

    // Do (synchronous) work...
    // ...
  }
  return 'Completed';
}
```

- **Client-Side Trigger**: When the main thread cancels the token (`token.cancel()`), Squadron automatically notifies the background worker that the task was canceled.
- **Worker-Side Responsibility**: The task implementation must periodically yield to the worker's event loop and check the token, then abort when cancellation is observed. An `async` declaration alone is not enough if the method performs CPU-bound work without awaiting.
- **Checking the token**: `token.throwIfCanceled()` is a synchronous check of the token's current state. It throws only if the cancellation signal has already reached the worker, such as during a previous yield; it cannot receive a signal while synchronous code is monopolizing the worker's event loop. `await token.refreshAndThrowIfCanceled()` yields before checking, giving a pending cancellation notification an opportunity to be processed, although it does not guarantee that a notification will arrive before the check.
- **Dropping Results**: Once canceled, the future awaiting the worker's result on the main thread is resolved with a `CanceledException` (or `TaskCanceledException`), and any eventual results produced by the worker are dropped.

## 2. Synchronous vs. Asynchronous Task Cancelation
It is crucial to understand how execution flow affects cancelation handling:

- **Asynchronous methods with regular async pauses**: The worker yields control to its event loop, allowing Squadron to receive the cancellation notification. A subsequent `throwIfCanceled()` can then observe it; `await token.refreshAndThrowIfCanceled()` yields and checks in one operation.
- **Synchronous methods or CPU-bound sections without async pauses**: The worker's event loop cannot process the notification while this code is running. A synchronous `throwIfCanceled()` can still detect cancellation that arrived during an earlier yield, but cannot detect a signal that has not yet been delivered. To make CPU-bound work cooperatively cancelable, structure it with periodic async pauses and check at those checkpoints. The client may observe cancellation while the worker continues until it can process the notification.

## 3. Alternative: Task Cancelation via Captured Tasks (`ValueTask`, `StreamTask`)
You can also cancel tasks without explicitly passing a `CancelationToken` by capturing the returned `ValueTask` (or `StreamTask`) handle from a worker pool instead of awaiting the invocation immediately:

```dart
// 1. Capture the task handle from a worker pool instead of awaiting directly
//    If the task streams results, use `scheduleStreamTask`
final task = workerPool.scheduleValueTask(
  (worker) => worker.computeLongTask(100),
);

// 2. Cancel the task later if needed
task.cancel('User aborted task');

try {
  final result = await task.value;
} on CanceledException catch (ex) {
  // Handles cancelation
}
```

Calling `task.cancel()` cancels the task on the client side; it does not notify or interrupt a worker that is already executing the task. The worker continues to completion, and its result is dropped. A task canceled while still pending will not be scheduled. To let a running worker stop cooperatively, pass a `CancelationToken` and cancel that token instead.

## 4. Canceling via Worker Pools (`pool.cancel` / `pool.cancelAll`)
When working with `WorkerPool`, you can manage and cancel tasks directly at the pool level:
- **`pool.cancel(task, [String? message])`**: Cancels a specific captured task.
- **`pool.cancelAll([String? message])`**: Cancels all active and queued tasks across the worker pool.

These methods use the same client-side cancellation behavior as `task.cancel()`; they do not send a cancellation signal to a running worker. A running `ValueTask` continues to completion and its result is dropped. A running `StreamTask` closes its client-facing stream, but this is not a worker cancellation signal. Use a `CancelationToken` when running worker code needs to observe cancellation and stop cooperatively.
