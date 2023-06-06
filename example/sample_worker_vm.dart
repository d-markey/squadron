import 'dart:async';

import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';

FutureOr<WorkerService> _initializer(WorkerRequest startRequest) {
  final channel = Channel.deserialize(startRequest.args[0])!;
  final identityClient = IdentityClient(channel);
  return SampleServiceImpl(identityClient);
}

void start(List command) => run(_initializer, command);
