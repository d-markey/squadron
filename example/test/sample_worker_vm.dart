import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';

WorkerService _initializer(WorkerRequest startRequest) {
  final channel = Channel.deserialize(startRequest.args[0])!;
  final identityClient = LoggingClient(channel);
  return SampleServiceImpl(identityClient);
}

void start(WorkerRequest command) => run(_initializer, command);
