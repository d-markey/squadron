import 'dart:async';

import 'package:squadron/squadron.dart';

import 'job.dart';
import 'job_worker.dart';

class JobWorkerPool extends WorkerPool<JobWorker> implements Job {
  JobWorkerPool(super.workerFactory, {super.concurrencySettings});

  @override
  Future<String> step1(int id) => execute((w) => w.step1(id));

  @override
  Future<String> step2(int id) => execute((w) => w.step2(id));

  @override
  Future<String> step3(int id) => execute((w) => w.step3(id));
}
