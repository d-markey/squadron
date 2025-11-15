import '../pool/worker_pool.dart';
import '../worker/worker.dart';
import 'target_platform.dart';

const localService = SquadronService.local();
const vmService = SquadronService.vm();
const sharedService = SharedServiceParam._();

@Deprecated('Use sharedService instead.')
const localWorker = SharedServiceParam._();

class SharedServiceParam {
  const SharedServiceParam._();
}

/// Annotation for service classes to be wrapped as workers.
class SquadronService {
  const SquadronService({
    this.pool = true,
    this.targetPlatform = TargetPlatform.all,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? '',
        local = false;

  const SquadronService.web({bool pool = true, String? baseUrl})
      : this(pool: pool, targetPlatform: TargetPlatform.web, baseUrl: baseUrl);

  const SquadronService.vm({bool pool = true})
      : this(pool: pool, targetPlatform: TargetPlatform.vm);

  const SquadronService.local()
      : pool = false,
        local = true,
        targetPlatform = TargetPlatform.none,
        baseUrl = '';

  /// Controls code generation of a [WorkerPool] exposing the target service
  /// class. `true` by default.
  final bool pool;

  /// Controls code generation of [Worker] and [WorkerPool]. When `true`, no
  /// [Worker] and no [WorkerPool] will be generated but instances of the service
  /// class can be shared with other workers.
  final bool local;

  /// Controls code generation of a entry points for various platforms.
  final int targetPlatform;

  /// For Web-based workers, indicates the [baseUrl] where the Web Worker will
  /// be exposed in production.
  final String baseUrl;
}
