import '../pool/worker_pool.dart';
import 'target_platform.dart';

const localService = SquadronService.local();

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
        targetPlatform = TargetPlatform.all,
        baseUrl = '';

  /// Controls code generation of a [WorkerPool] exposing the target service class.
  /// `true` by default.
  final bool pool;

  /// Controls code generation of a [LocalWorkerClient] exposing the target service class.
  /// `false` by default.
  final bool local;

  /// Controls code generation of a entry points for various platforms.
  final int targetPlatform;

  /// For Web-based workers, indicates the [baseUrl] where the Web Worker will
  /// be exposed in production.
  final String baseUrl;
}
