import 'dart:isolate';

import 'package:squadron/squadron_service.dart';

dynamic getUntransferableImpl() => ReceivePort();

WorkerChannel? getWorkerChannelImpl() =>
    WorkerChannel.deserialize(ReceivePort().sendPort);
