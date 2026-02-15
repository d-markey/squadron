import 'package:squadron/squadron.dart';

import 'job_worker.dart';
import 'job_worker_pool.dart';
import 'vm.dart' as vm;

void main() async {
  final pool = JobWorkerPool(
    (mk) => JobWorker(vm.start),
    concurrencySettings: ConcurrencySettings(
      minWorkers: 2,
      maxWorkers: 2,
      maxParallel: 1,
    ),
  );

  try {
    await pool.start().then((_) => report(null, 'pool initialization'));

    print(
      '\n'
      '======= Starting multi-steps jobs (non-captured workers) =======\n'
      '\n'
      'Executing multi-steps jobs via the pool will block jobs in high-contention scenarios (more jobs than workers).\n',
    );

    // Run 5 multi-steps jobs in parallel
    sw.reset();
    await Future.wait(
      List.generate(5, (i) async {
        // each step will require scheduling from Squadron
        final r1 = await pool.step1(i).then((x) => report(x, 'step 1', i));
        final r2 = await pool.step2(i).then((x) => report(x, 'step 2', i));
        final r3 = await pool.step3(i).then((x) => report(x, 'step 3', i));
        print('Job #$i results: ${[r1, r2, r3]}');
      }),
    );

    print(
      '\n'
      '======= Starting multi-steps jobs (captured workers) =======\n'
      '\n'
      'Capturing workers eliminates additional scheduling from Squadron, allowing multi-steps jobs to complete earlier.\n',
    );

    // Run 5 multi-steps jobs in parallel
    sw.reset();
    await Future.wait(
      List.generate(5, (i) {
        return pool.execute((w) async {
          // the captured worker will handle the job steps sequentially
          // steps will execute without requiring additional scheduling from Squadron
          final r1 = await w.step1(i).then((x) => report(x, 'step 1', i));
          final r2 = await w.step2(i).then((x) => report(x, 'step 2', i));
          final r3 = await w.step3(i).then((x) => report(x, 'step 3', i));
          print('Job #$i results: ${[r1, r2, r3]}');
        });
      }),
    );
  } finally {
    pool.stop();
  }
}

final sw = Stopwatch()..start();

T report<T>(T result, String message, [int? jobId]) {
  print(jobId == null
      ? '[${sw.elapsed}] $message'
      : '[${sw.elapsed}] Job #$jobId: $message');
  return result;
}
