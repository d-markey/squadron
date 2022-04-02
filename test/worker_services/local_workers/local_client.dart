import 'package:squadron/squadron_local_worker.dart';

import 'local_service.dart';

class LocalClient extends LocalWorkerClient implements LocalService {
  LocalClient(Channel channel) : super(channel);

  @override
  Future<String> getId() => send(LocalService.getIdCommand, []);

  @override
  Future<bool> throwException() => send(LocalService.throwExceptionCommand, []);

  @override
  Stream<int> sequence(int count) =>
      stream(LocalService.sequenceCommand, [count]);
}
