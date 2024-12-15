import 'dart:async';

import 'package:logger/web.dart';
import 'package:using/using.dart';

import 'exceptions/exception_manager.dart';
import 'exceptions/task_terminated_exception.dart';

abstract interface class IWorker implements Releasable {
  Logger? channelLogger;

  ExceptionManager get exceptionManager;

  FutureOr<void> start();
  FutureOr<void> stop();

  void terminate([TaskTerminatedException? ex]);
}
