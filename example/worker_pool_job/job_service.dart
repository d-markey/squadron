import 'dart:async';

import 'package:squadron/squadron.dart';

import 'job.dart';

class JobService implements Job, WorkerService {
  @override
  Future<String> step1(int id) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate work
    return 'Step 1 completed for job #$id';
  }

  @override
  Future<String> step2(int id) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate work
    return 'Step 2 completed for job #$id';
  }

  @override
  Future<String> step3(int id) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate work
    return 'Step 3 completed for job #$id';
  }

  static const step1Command = 1;
  static const step2Command = 2;
  static const step3Command = 3;

  @override
  late final operations = OperationsMap({
    step1Command: (r) => step1(r.args[0]),
    step2Command: (r) => step2(r.args[0]),
    step3Command: (r) => step3(r.args[0]),
  });
}
