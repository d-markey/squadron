import 'package:squadron/squadron_service.dart';

import '../worker_services/failing_service.dart';

void start(Map command) => run((startRequest) {
      throw Exception('Intentional failure');
    }, command);

void startWithMissingCommand(Map command) =>
    run((startRequest) => FailingService() /* intentionally missing command */);
