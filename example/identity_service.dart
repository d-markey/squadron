import 'dart:async';

import 'package:squadron/squadron.dart';

// The service interface
abstract class IdentityService implements WorkerService {
  FutureOr<String> whoAreYou();

  static const whoAreYouCommand = 1;
}

// The service implementation
class IdentityServiceImpl extends IdentityService {
  @override
  String whoAreYou() {
    return Squadron.id;
  }

  @override
  late final Map<int, CommandHandler> operations = {
    IdentityService.whoAreYouCommand: (req) => whoAreYou(),
  };
}

// The service client: this class will be used in workers that need to call the service implementation
class IdentityClient extends LocalWorkerClient implements IdentityService {
  IdentityClient(Channel channel) : super(channel);

  @override
  Future<String> whoAreYou() => send(IdentityService.whoAreYouCommand, []);
}
