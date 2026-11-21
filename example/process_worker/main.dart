import 'dart:io' as current_process show pid;

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/native/inproc/_typedefs.dart';
import 'package:squadron/src/_impl/native/ipc/_typedefs.dart';

import '../hello_world/hello_world_worker_pool.dart';
import '../hello_world/hello_world_worker_vm_entrypoint.dart';

void main(List<String> args) async {
  print(
      'Program running in process ${current_process.pid.hex} / main thread $threadId');

  final entrypoint = args.contains('ipc') ? ipcEntryPoint : vmEntryPoint;

  void $printWorkerProcessId(PlatformThread workerThread) {
    if (workerThread is IpcPlatformThread) {
      print(
          '> Worker process started (pid: ${workerThread.pid.hex} [${workerThread.pid}])');
    } else if (workerThread is InProcPlatformThread) {
      print('> Worker isolate started (id: ${workerThread.hashCode.hex})');
    }
  }

  final worker = HelloWorldWorkerPool(entrypoint,
      threadHook: $printWorkerProcessId,
      concurrencySettings:
          ConcurrencySettings(minWorkers: 1, maxWorkers: 2, maxParallel: 2));
  print('Starting worker pool...');
  try {
    await worker.start();
    print('Worker pool started');
  } catch (e, st) {
    print('Error starting worker: $e\n$st');
    return;
  }

  try {
    final tasks = <Future<void>>[];
    for (var name in ['Mia', 'Bob', 'Eva', 'Ada', 'Max', 'Joy', 'Ray', 'Ben']) {
      tasks.add(worker
          .sayHello(name, delayInSec: 2)
          .then((m) => print('    --> $m')));
    }

    await Future.wait(tasks);

    final stats = worker.stats.toList();
    print('${tasks.length} tasks handled by ${stats.length} workers.');
  } finally {
    // make sure all workers/worker pools are stopped
    worker.stop();
  }
}
