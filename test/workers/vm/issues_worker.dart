import 'package:squadron/squadron.dart';

import '../../worker_services/issues_service.dart';
import '_platform.dart';

void start(WorkerRequest command) => run(
      (startReq) {
        setConverter(startReq);
        return IssuesService();
      },
      command,
    );
