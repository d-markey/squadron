import 'package:squadron/squadron.dart';

import 'local_service.dart';

class LocalClient extends LocalWorkerClient implements LocalService {
  LocalClient(super.channel);

  @override
  Future<String> getId() => send(LocalService.getIdCommand);

  @override
  Future<bool> throwException() => send(LocalService.throwExceptionCommand);

  @override
  Stream<int> sequence(int count) =>
      stream(LocalService.sequenceCommand, args: [count]);
}
