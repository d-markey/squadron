import 'package:squadron/squadron_service.dart';

import '../worker_services/test_service.dart';

void start(Map command) => run((startRequest) => TestService(), command);

void startWithException(Map command) => run((startRequest) {
      throw Exception('Intentional failure');
    }, command);

void startWithMissingCommand(Map command) =>
    run((startRequest) => TestService() /* intentionally missing command */);

void startWithInvalidCommand(Map command) =>
    run((startRequest) => TestService(invalid: true), command);
