Multithreading and worker pools in Dart

## Features

`Worker` class: a base worker class managing an Isolate and the communication from clients to the worker's Isolate.

`WorkerPool<W>` class: a worker pool for `W` workers. The number of workers is configurable as well as the degree of concurrent workloads distributed to workers in the pool.

## Getting started

Import squadron from your `pubspec.yaml` file:

```
dependencies:
   squadron: ^1.0.0
```

## Usage

First implement a worker to offload specific tasks.

The example below implements a `cpuOperation()` method (where processing is essentially CPU-bound) and a `ioOperation()` method (where processing is essentially I/O-bound).

```dart
import 'dart:isolate';

import 'package:squadron/squadron.dart';

class SampleWorker extends Worker {
  SampleWorker() : super(SampleWorker._main);

  @override
  final startArguments = [];

  Future<int> cpuOperation(int number) {
    return send<int>(_cpuOperation, [number]);
  }

  Future<int> ioOperation(int number) {
    return send<int>(_ioOperation, [number]);
  }

  // private implementation, this is the thread's main program
  static const _cpuOperation = 1;
  static const _ioOperation = 2;

  static void _main(List command) {
    final receiver = ReceivePort();
    WorkerRequest.fromMessage(command).connect(receiver);

    receiver.listen((command) async {
      WorkerRequest? req;
      try {
        req = WorkerRequest.fromMessage(command);
        if (req.command == null) {
          receiver.close();
          return;
        }
        switch (req.command) {
          case _cpuOperation:
            req.reply(cpuOperationImpl(req.args[0]));
            return;
          case _ioOperation:
            req.reply(await ioOperationImpl(req.args[0]));
            return;
          default:
            req.exception(WorkerException('unknown message ${req.command}'),
                StackTrace.current);
            return;
        }
      } on WorkerException catch (e, st) {
        req?.exception(e, st);
      } catch (e, st) {
        req?.exception(
            WorkerException('unexpected exception: ${e.runtimeType} => $e}',
                stackTrace: st.toString()),
            st);
      }
    });
  }

  static int cpuOperationImpl(int n) {
    var start = DateTime.now().millisecondsSinceEpoch;
    var elapsed = 0;
    while (elapsed < 2) {
      elapsed = DateTime.now().millisecondsSinceEpoch - start;
    }
    return n;
  }

  static Future<int> ioOperationImpl(int n) async {
    await Future.delayed(Duration(milliseconds: 2));
    return n;
  }
}
```

You can then distribute workloads to a worker pool, e.g.:

```dart
    var pool = WorkerPool(() => SampleWorker(), maxWorkers: 4, maxParallel: 2);
    await pool.start();

    var n = 42;
    var cpuResult = await pool.compute((w) => w.cpuOperation(n));
    var ioResult = await pool.compute((w) => w.ioOperation(n));
```

