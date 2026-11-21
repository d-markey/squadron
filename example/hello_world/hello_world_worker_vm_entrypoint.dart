import 'package:squadron/squadron.dart';
import 'package:squadron/squadron_process_runner.dart';

import 'hello_world_worker_service.dart';

/// Use squadron_builder to generate this code.
/// Manual implementation is discouraged.
///
/// See https://github.com/d-markey/squadron_builder/tree/main/example/hello_world
///
/// Initializes the HelloWorldWorkerService running in the worker thread.
const vmEntryPoint = InProcEntryPoint(_start);

void _start(WorkerRequest command) => runWorkerService(
      (_) => HelloWorldWorkerService(),
      command,
    );

const ipcEntryPoint = IpcEntryPoint(
    'example/process_worker/hello_world_worker_process_entrypoint.exe');

void main() async {
  runWorkerProcess((_) => HelloWorldWorkerService());
}
