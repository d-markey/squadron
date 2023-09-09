import 'dart:isolate';

import 'package:squadron/squadron.dart';

dynamic getUntransferableImpl() => ReceivePort();

WorkerChannel? getWorkerChannelImpl() =>
    WorkerChannel.deserialize(ReceivePort().sendPort);
