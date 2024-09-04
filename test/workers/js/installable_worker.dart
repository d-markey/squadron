import 'package:squadron/squadron.dart';

import '../../worker_services/installable_service.dart';
import '_platform.dart';

void main() => run(
      (startReq) {
        setConverter(startReq);
        return InstallableService(
            throwOnInstall: startReq.args[1],
            throwOnUninstall: startReq.args[2]);
      },
    );
