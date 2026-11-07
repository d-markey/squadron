---
name: squadron-worker-affinity
description: Use when implementing stateful or workflow-like Squadron workers, grouping related service calls into one WorkerPool task, keeping calls on the same worker instance, avoiding repeated pool scheduling, or choosing between execute, scheduleValueTask, and scheduleStreamTask.
---

# Squadron Worker Affinity and Task Batching

Each generated service method called directly on a worker pool schedules its own task. When several calls belong together, put the entire workflow in one `execute` callback and invoke the worker methods through that callback's `worker` argument:

```dart
await pool.execute((worker) async {
  await worker.initializeWorkflow(...);
  final one = await worker.workflowStep1(...);
  final two = await worker.workflowStep2(...);

  if (shouldContinue(one, two)) {
    return worker.workflowStep3(...);
  }

  return one + two;
});
```

The pool schedules the callback as one task and assigns it a worker. Every `worker.*` call made through that argument uses the same worker instance. The task occupies that worker's pool slot until the callback's future completes. This is useful when:

- The worker holds state across workflow calls, such as an initialized session or transaction.
- The ordered steps must not be interleaved with another pool task on the same worker.
- You want to avoid putting each generated pool method call back through the pool's scheduling queue.

The calls still cross the worker communication boundary individually. Batching avoids repeated pool scheduling; it does not combine the service requests into one message. Await calls sequentially when order or worker-side state matters. Do not start them concurrently with `Future.wait` if one call must observe the effects of another.

## Required concurrency setting for stateful workflows

For a stateful workflow that must keep its worker exclusive from other pool tasks until all steps finish, use one `execute` callback for the entire workflow and configure the pool with `maxParallel: 1`:

```dart
final pool = MyServiceWorkerPool(
  activator,
  concurrencySettings: ConcurrencySettings(
    minWorkers: 1,
    maxWorkers: 4,
    maxParallel: 1,
  ),
);
```

`execute` keeps the same assigned worker for the callback. `maxParallel: 1` ensures the pool will not assign another scheduled task to that worker while the workflow callback is still running. Both are needed for this exclusivity guarantee: separate pool calls can be assigned to different workers, and with `maxParallel > 1` another pool task may run on the same worker and interleave with the workflow.

`maxWorkers` can remain greater than one so unrelated tasks can run on other workers. Setting both `maxWorkers: 1` and `maxParallel: 1` serializes the whole pool through a single worker, which may be appropriate when global serialization is intended but otherwise gives up the pool's worker-level parallelism.

## Canceling a workflow

Create one `CancelationToken` before scheduling the workflow. Pass it to worker methods that accept a token, and check it between steps so cancellation also stops the client-side workflow from starting later steps:

```dart
final token = CancelableToken(); // or TimeoutToken

final workflow = pool.execute((worker) async {
  await worker.initializeWorkflow(..., token);
  token.throwIfCanceled();

  final one = await worker.workflowStep1(..., token);
  token.throwIfCanceled();

  final two = await worker.workflowStep2(..., token);
  token.throwIfCanceled();

  if (shouldContinue(one, two)) {
    return worker.workflowStep3(..., token);
  }
  return one + two;
});

// Keep `token` and call this from a later user action:
void cancelWorkflow() => token.cancel('User aborted workflow');

await workflow;
```

`execute` is the primary pattern for a workflow: it schedules the entire sequence as one task while preserving worker affinity. The same token pattern also works with `scheduleValueTask` or `scheduleStreamTask` when you need a task handle or a stream. Pass the token only to methods whose service signatures accept it. Check between calls even when passing the token into service methods: a method may not support cooperative cancellation, or may not check its token often enough, and the between-step check prevents starting subsequent steps after the token is canceled.

Canceling the token is the mechanism that notifies in-flight service calls and lets them stop cooperatively when they check it. By contrast, calling `task.cancel()` on a scheduled task handle only cancels its client-side result; it does not stop a running workflow callback or notify the worker. As with all token cancellation, worker code must yield to its event loop and check the token to observe a newly delivered signal.

## Task handles and streams

Use `scheduleValueTask` instead of `execute` when you also need a `ValueTask` handle, for example to inspect task status or retain the result future:

```dart
final task = pool.scheduleValueTask((worker) async {
  await worker.initializeWorkflow(...);
  final one = await worker.workflowStep1(...);
  return worker.workflowStep2(one);
});

final result = await task.value;
```

For a stream-producing workflow, use `scheduleStreamTask` and invoke service methods through its assigned worker:

```dart
final task = pool.scheduleStreamTask<int>((worker) async* {
  final one = await worker.workflowStep1(...);
  yield one;

  final two = await worker.workflowStep2(...);
  yield two;
});

await for (final value in task.stream) {
  // Handle each result.
}
```

## Do not re-enter the pool from a callback

Inside an `execute`, `scheduleValueTask`, or `scheduleStreamTask` callback, invoke service methods on the callback's `worker` argument. Do not call generated service methods on the pool or schedule another task on that same pool and wait for it:

```dart
await pool.execute((worker) async {
  await worker.workflowStep1(...); // Correct: uses this callback's worker.

  // Avoid: schedules a separate task through the pool.
  // await pool.workflowStep2(...);
  // await pool.execute((otherWorker) => otherWorker.workflowStep2(...));
});
```

Re-entering the pool creates a separate task. It may run on a different worker, breaking the workflow's worker affinity and state assumptions. It can also deadlock: with `maxWorkers: 1` and `maxParallel: 1`, the outer callback occupies the only worker slot while waiting for the nested task, which cannot start until that slot is released. If multiple outer callbacks occupy all available workers and wait for nested pool tasks, the same deadlock can occur.

Worker affinity applies only to the `worker` argument within one scheduled callback; it does not pin future callbacks to the same instance. Keep the full stateful workflow in the callback and call its worker directly.
