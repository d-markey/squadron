import 'dart:async';

import 'package:squadron/squadron.dart';

// The service interface
abstract class IdentityService implements WorkerService {
  FutureOr<String> whoAreYou();

  static const whoAreYouCommand = 1;

  @override
  late final OperationsMap operations = OperationsMap({
    IdentityService.whoAreYouCommand: (req) => whoAreYou(),
  });
}

// The service implementation
class IdentityServiceImpl extends IdentityService {
  @override
  String whoAreYou() => threadId;
}

// The service client: this class will be used in workers that need to call the service implementation
class IdentityClient extends LocalWorkerClient implements IdentityService {
  IdentityClient(super.channel);

  @override
  Future<String> whoAreYou() => send(IdentityService.whoAreYouCommand)
      .then(Squadron.converter.value<String>());
}
