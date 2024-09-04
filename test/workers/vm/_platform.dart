import 'dart:isolate';

import 'package:squadron/squadron.dart';

dynamic getUnsendable() => ReceivePort();

void setConverter(WorkerRequest startReq) {
  // always use default converter
}
