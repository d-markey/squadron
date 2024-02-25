import 'dart:html';

import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

class Unsendable {}

dynamic getUnsendable() => Unsendable();

WorkerChannel? getWorkerChannel(Logger? logger) =>
    WorkerChannel.deserialize(MessageChannel().port1, logger);

String get threadId {
  dynamic object;
  try {
    object = WorkerGlobalScope.instance;
  } catch (_) {
    object = window;
  }
  return '0x${object.hashCode.toRadixString(8).padLeft(8, '0')}';
}
