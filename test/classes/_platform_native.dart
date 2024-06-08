import 'dart:isolate';

import 'package:squadron/squadron.dart';

dynamic getUnsendable() => ReceivePort();

WorkerChannel? getWorkerChannel(Logger? logger) =>
    WorkerChannel.deserialize(ReceivePort().sendPort, logger);

final String threadId = Isolate.current.hashCode.hex;
