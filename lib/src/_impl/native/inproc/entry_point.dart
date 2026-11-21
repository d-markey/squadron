import '../../../worker/entry_point.dart';
import '../../../worker/worker_request.dart';

class InProcEntryPoint extends EntryPoint {
  const InProcEntryPoint(this.run);

  final void Function(WorkerRequest) run;
}
