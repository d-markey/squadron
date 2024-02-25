import 'dart:isolate';

import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

dynamic getUnsendable() => ReceivePort();

WorkerChannel? getWorkerChannel(Logger? logger) =>
    WorkerChannel.deserialize(ReceivePort().sendPort, logger);

String get threadId =>
    '0x${Isolate.current.hashCode.toRadixString(8).padLeft(8, '0')}';
