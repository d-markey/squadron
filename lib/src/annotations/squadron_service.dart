import '../worker_pool.dart';

/// Annotation for service classes to be wrapped as workers.
class SquadronService {
  const SquadronService(
      {this.pool = true, this.vm = true, this.web = true, this.baseUrl = ''});

  /// Controls code generation of a [WorkerPool] exposing the target service class.
  /// `true` by default.
  final bool pool;

  /// Controls code generation of a native entry point (for Isolate). `true` by
  /// default.
  final bool vm;

  /// Controls code generation of a Web entry point (for Web Worker). `true` by
  /// default.
  final bool web;

  /// For Web-based workers, indicates the [baseUrl] where the Web Worker will
  /// be exposed in production.
  final String baseUrl;
}
