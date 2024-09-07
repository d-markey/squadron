import 'package:squadron/squadron.dart';

import '../../worker_services/installable_service.dart';

void start(WorkerRequest command) {
  run(
    (startReq) => InstallableService(
      throwOnInstall: startReq.args[0],
      throwOnUninstall: startReq.args[1],
    ),
    command,
  );
}
