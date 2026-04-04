// ignore_for_file: constant_identifier_names

class BuildOptions {
  static const isVm = !isJs && !isWasm;

  static const isJs = bool.fromEnvironment(
    'dart.tool.dart2js',
    defaultValue: false,
  );

  static const isWasm = bool.fromEnvironment(
    'dart.tool.dart2wasm',
    defaultValue: false,
  );

  static const withInternalLogging = !bool.fromEnvironment(
    'squadron.no_internal_logging',
    defaultValue: false,
  );

  static const withCrossWorkerLogging = !bool.fromEnvironment(
    'squadron.no_cross_worker_logging',
    defaultValue: false,
  );

  static const withTravelTime = !bool.fromEnvironment(
    'squadron.travel_time',
    defaultValue: false,
  );
}
