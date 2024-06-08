import 'dart:html';

import 'package:squadron/squadron.dart';

class Unsendable {}

dynamic getUnsendable() => Unsendable();

WorkerChannel? getWorkerChannel(Logger? logger) =>
    WorkerChannel.deserialize(MessageChannel().port1, logger);

final String threadId = Object().hashCode.hex; // unique per event loop
