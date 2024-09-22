import 'dart:async';

import 'package:logger/web.dart';
import 'package:using/using.dart';

import 'exceptions/exception_manager.dart';

abstract interface class IWorker implements Releasable {
  Logger? channelLogger;

  ExceptionManager get exceptionManager;

  FutureOr<void> start();
  FutureOr<void> stop();
}
