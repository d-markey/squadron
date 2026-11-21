import 'package:squadron/squadron.dart';

import '../../worker_services/installable_service.dart';

final entryPoint = InProcEntryPoint(_start);

void _start(WorkerRequest command) {
  runWorkerService(
    (startReq) => InstallableService(
      throwOnInstall: startReq.args[0],
      throwOnUninstall: startReq.args[1],
    ),
    command,
  );
}
