import 'package:squadron/squadron.dart';

import '../worker_services/test_service.dart';

void start(List command) => run((startRequest) => TestService(), command);

void startWithException(List command) => run((startRequest) {
      throw Exception('Intentional failure');
    }, command);

void startWithMissingCommand(List command) =>
    run((startRequest) => TestService() /* intentionally missing command */);

void startWithInvalidCommand(List command) =>
    run((startRequest) => TestService(invalid: true), command);
