import 'dart:html';

import 'package:squadron/squadron.dart';

// ignore: unused_element
final _ = (() {
  print('Imported _platform_browser.dart');
})();

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
