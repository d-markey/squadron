import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';

void start(Map command) => run((startRequest) {
      final channel = Channel.deserialize(startRequest.args[0])!;
      final identityClient = IdentityClient(channel);
      return SampleServiceImpl(identityClient);
    }, command);
