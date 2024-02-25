import 'package:squadron/squadron.dart';

import '../worker_services/installable_service.dart';

void main() => run(
      (startRequest) => InstallableService(
          throwOnInstall: startRequest.args[0],
          throwOnUninstall: startRequest.args[1]),
    );
