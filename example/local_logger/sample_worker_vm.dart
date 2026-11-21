import 'package:squadron/squadron.dart';

import 'logging_service.dart';
import 'sample_service.dart';

WorkerService _initializer(WorkerRequest startRequest) {
  final channel = Channel.deserialize(startRequest.args[0])!;
  final identityClient = LoggingClient(channel);
  return SampleServiceImpl(identityClient);
}

final entryPoint = InProcEntryPoint(_start);

void _start(WorkerRequest command) => runWorkerService(_initializer, command);
