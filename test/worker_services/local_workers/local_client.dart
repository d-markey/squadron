import 'package:squadron/squadron.dart';

import 'local_service.dart';

class LocalClient extends LocalWorkerClient implements LocalService {
  LocalClient(super.channel);

  @override
  Future<String> getId() =>
      send(LocalService.getIdCommand).then(platformConverter.v<String>());

  @override
  Future<bool> throwException() => send(LocalService.throwExceptionCommand)
      .then(platformConverter.v<bool>());

  @override
  Stream<int> sequence(int count) =>
      stream(LocalService.sequenceCommand, args: [count])
          .map(platformConverter.v<int>());
}
