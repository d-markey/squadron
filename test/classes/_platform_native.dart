import 'dart:isolate';

import 'package:squadron/squadron.dart';

// ignore: unused_element
final _ = (() {
  print('Imported _platform_native.dart');
})();

dynamic getUnsendable() => ReceivePort();

WorkerChannel? getWorkerChannel(Logger? logger) =>
    WorkerChannel.deserialize(ReceivePort().sendPort, logger);

String get threadId =>
    '0x${Isolate.current.hashCode.toRadixString(8).padLeft(8, '0')}';
