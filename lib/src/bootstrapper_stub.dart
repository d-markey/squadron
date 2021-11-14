import 'dart:async';

import 'bootstrapper.dart' show WorkerInitializer;

FutureOr bootstrap(WorkerInitializer initializer, Map command) {
  throw UnsupportedError(
    'bootstrap() is not supported on this platform.');
}
