import '../xplat/_worker_runner.dart';

extension VmWorkerRunnerExt on WorkerRunner {
  void handle(dynamic message) => processMessage(message);
}
