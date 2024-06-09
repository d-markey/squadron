import 'package:squadron/squadron.dart';

import '../../worker_services/installable_service.dart';

void start(WorkerRequest command) => run(
      (startRequest) => InstallableService(
          throwOnInstall: startRequest.args[0],
          throwOnUninstall: startRequest.args[1]),
      command,
    );
