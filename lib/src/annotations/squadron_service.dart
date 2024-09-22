import '../pool/worker_pool.dart';

/// Annotation for service classes to be wrapped as workers.
class SquadronService {
  const SquadronService({
    this.pool = true,
    this.targetPlatform = TargetPlatform.all,
    String? baseUrl,
  }) : baseUrl = baseUrl ?? '';

  const SquadronService.web({bool pool = true, String? baseUrl})
      : this(pool: pool, targetPlatform: TargetPlatform.web, baseUrl: baseUrl);

  const SquadronService.vm({bool pool = true})
      : this(pool: pool, targetPlatform: TargetPlatform.vm);

  /// Controls code generation of a [WorkerPool] exposing the target service class.
  /// `true` by default.
  final bool pool;

  /// Controls code generation of a entry points for various platforms.
  final int targetPlatform;

  /// For Web-based workers, indicates the [baseUrl] where the Web Worker will
  /// be exposed in production.
  final String baseUrl;
}

final class TargetPlatform {
  static const vm = 1;
  static const js = 2;
  static const wasm = 4;

  static const web = js | wasm;
  static const all = vm | js | wasm;
}

extension TargetPlatformExt on int {
  bool get hasVm => (this & TargetPlatform.vm) != 0;
  bool get hasJs => (this & TargetPlatform.js) != 0;
  bool get hasWasm => (this & TargetPlatform.wasm) != 0;
}
