import 'package:squadron/squadron.dart';

import '../../worker_services/installable_service.dart';

void main() {
  run(
    (startReq) => InstallableService(
      throwOnInstall: startReq.args[0],
      throwOnUninstall: startReq.args[1],
    ),
  );
}
