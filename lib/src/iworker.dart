import 'dart:async';

import 'package:logger/logger.dart';

import 'exceptions/exception_manager.dart';

abstract class IWorker {
  Logger? channelLogger;

  ExceptionManager get exceptionManager;

  FutureOr start() {}
  FutureOr stop() {}
}
