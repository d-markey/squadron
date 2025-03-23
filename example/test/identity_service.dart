import 'dart:async';

import 'package:squadron/squadron.dart';

// The service interface
abstract class LoggingService implements WorkerService {
  FutureOr<void> log(String threadId, Object message);

  static const logCommand = 1;

  @override
  late final OperationsMap operations = OperationsMap({
    LoggingService.logCommand: (req) =>
        log(Squadron.converter.value<String>()(req.args[0]), req.args[1]),
  });
}

// The service implementation
class LoggingServiceImpl extends LoggingService {
  @override
  void log(String threadId, Object message) {
    print('[LOG ${DateTime.now()}] [$threadId] $message');
  }
}

// The service client: this class will be used in workers that need to call the service implementation
class LoggingClient extends LocalWorkerClient implements LoggingService {
  LoggingClient(super.channel);

  @override
  void log(String threadId, Object message) =>
      send(LoggingService.logCommand, args: [threadId, message]);
}
