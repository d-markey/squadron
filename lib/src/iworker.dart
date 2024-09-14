import 'dart:async';

import 'package:logger/logger.dart';
import 'package:using/using.dart';

import 'exceptions/exception_manager.dart';

abstract class IWorker implements Releasable {
  Logger? channelLogger;

  ExceptionManager get exceptionManager;

  FutureOr<void> start() {}
  FutureOr<void> stop() {}
}
