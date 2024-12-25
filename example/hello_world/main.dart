import 'package:squadron/squadron.dart';

import 'hello_world_worker_pool.dart';
import 'hello_world_worker_vm_entrypoint.dart';

void main() async {
  print('Program running in main thread $threadId');

  final workerPool = HelloWorldWorkerPool(
    start,
    concurrencySettings: ConcurrencySettings.threeCpuThreads,
  );
  await workerPool.start();

  try {
    final tasks = <Future<void>>[];
    for (var name in ['Mia', 'Bob', 'Eva', 'Ada', 'Max', 'Joy', 'Ray', 'Ben']) {
      tasks.add(workerPool.sayHello(name).then((m) => print('    --> $m')));
    }

    await Future.wait(tasks);

    final stats = workerPool.stats.toList();
    print('${tasks.length} tasks handled by ${stats.length} workers.');
  } finally {
    // make sure all workers/worker pools are stopped
    workerPool.stop();
  }
}
