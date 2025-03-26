import 'dart:async';

import '_impl/xplat/_typedefs.dart'
    if (dart.library.io) '_impl/native/_typedefs.dart'
    if (dart.library.html) '_impl/web/_typedefs.dart'
    if (dart.library.js) '_impl/web/_typedefs.dart'
    if (dart.library.js_interop) '_impl/web/_typedefs.dart' as impl;
import 'worker/worker_request.dart';
import 'worker_service.dart';

typedef EntryPoint = impl.EntryPoint;
typedef PlatformChannel = impl.PlatformChannel;
typedef PlatformThread = impl.PlatformThread;
typedef PlatformThreadHook = impl.PlatformThreadHook;

typedef WorkerInitializer = FutureOr<WorkerService> Function(
    WorkerRequest startRequest);
typedef CommandHandler = FutureOr<dynamic> Function(WorkerRequest req);
typedef StreamCanceler = void Function();

typedef Cast<T> = T Function(dynamic);

extension type OperationsMap(Map<int, CommandHandler> _ops) {
  CommandHandler? operator [](int key) => _ops[key];

  Iterable<int> get keys => _ops.keys;
}
