import 'package:squadron/squadron.dart';

import 'local_service.dart';

class LocalClient extends LocalWorkerClient implements LocalService {
  LocalClient(super.channel);

  @override
  Future<String> getId() =>
      send(LocalService.getIdCommand).then(Squadron.converter.value<String>());

  @override
  Future<bool> throwException() => send(LocalService.throwExceptionCommand)
      .then(Squadron.converter.value<bool>());

  @override
  Stream<int> sequence(int count) =>
      stream(LocalService.sequenceCommand, args: [count])
          .map(Squadron.converter.value<int>());
}
