import 'dart:js_interop';

import 'package:squadron/squadron.dart';
import 'package:web/web.dart' as web;

// ignore: unused_element
final _ = (() {
  print('Imported _platform_wasm.dart');
})();

@JS()
external web.DedicatedWorkerGlobalScope get self;

class Unsendable {}

dynamic getUnsendable() => Unsendable();

WorkerChannel? getWorkerChannel(Logger? logger) =>
    WorkerChannel.deserialize(web.MessageChannel().port1, logger);

String get threadId {
  dynamic object;
  try {
    object = self;
  } catch (_) {
    object = web.window;
  }
  return '0x${object.hashCode.toRadixString(8).padLeft(8, '0')}';
}
