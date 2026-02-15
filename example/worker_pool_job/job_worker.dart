import 'dart:async';

import 'package:squadron/squadron.dart';

import 'job.dart';
import 'job_service.dart';

class JobWorker extends Worker implements Job {
  JobWorker(super.entryPoint, {super.threadHook, super.exceptionManager});

  @override
  List? getStartArgs() => null;

  @override
  Future<String> step1(int id) =>
      send(JobService.step1Command, args: [id]).then((x) => x as String);

  @override
  Future<String> step2(int id) =>
      send(JobService.step2Command, args: [id]).then((x) => x as String);

  @override
  Future<String> step3(int id) =>
      send(JobService.step3Command, args: [id]).then((x) => x as String);
}
