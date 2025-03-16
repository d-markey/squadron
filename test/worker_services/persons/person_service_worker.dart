import 'package:squadron/squadron.dart';

import '../../src/test_context.dart';
import '../squadron_version.dart';
import 'person.dart';
import 'person_service.dart';

base class PersonWorkerPool extends WorkerPool<PersonWorker>
    with PoolVersion<PersonWorker>
    implements PersonService {
  PersonWorkerPool._(
      super._workerFactory, ConcurrencySettings? concurrencySettings,
      [ExceptionManager? exceptionManager])
      : super(
          concurrencySettings:
              concurrencySettings ?? ConcurrencySettings.fourIoThreads,
          exceptionManager: exceptionManager,
        );

  PersonWorkerPool(TestContext context,
      [ConcurrencySettings? concurrencySettings,
      ExceptionManager? exceptionManager])
      : this._(
          (ExceptionManager exceptionManager) =>
              PersonWorker(context, exceptionManager: exceptionManager),
          concurrencySettings ?? ConcurrencySettings.fourIoThreads,
          exceptionManager,
        );

  @override
  Future<String> getKindType(Person person, Person other) =>
      execute((w) => w.getKindType(person, other));
}

base class PersonWorker extends Worker
    with WorkerVersion
    implements PersonService {
  PersonWorker._(super.entryPoint, PlatformThreadHook? hook,
      ExceptionManager? exceptionManager)
      : super(
          threadHook: hook,
          exceptionManager: exceptionManager,
        );

  PersonWorker(TestContext context,
      {PlatformThreadHook? hook, ExceptionManager? exceptionManager})
      : this._(
          context.entryPoints.person!,
          hook,
          exceptionManager,
        );

  @override
  List? getStartArgs() => null;

  @override
  Future<String> getKindType(Person person, Person other) async {
    final cin = MarshalingContext();
    final marshaler = const PersonMarshaler();
    return await send(PersonService.getKindTypeCommand, args: [
      marshaler.marshal(person, cin),
      marshaler.marshal(other, cin),
    ]);
  }
}
