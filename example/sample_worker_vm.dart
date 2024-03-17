import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';

WorkerService _initializer(WorkerRequest startRequest) {
  final logger = Logger();
  final channel = Channel.deserialize(startRequest.args[0], logger)!;
  final identityClient = IdentityClient(channel);
  return SampleServiceImpl(identityClient);
}

void start(List command) => run(_initializer, command);
