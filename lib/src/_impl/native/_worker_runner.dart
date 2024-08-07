import '../../worker/worker_request.dart';
import '../xplat/_worker_runner.dart';

extension VmWorkerRunnerExt on WorkerRunner {
  void handle(dynamic message) =>
      processRequest(WorkerRequestExt.from(message));
}
