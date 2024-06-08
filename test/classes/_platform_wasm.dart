import 'package:squadron/squadron.dart';
import 'package:web/web.dart' as web;

class Unsendable {}

dynamic getUnsendable() => Unsendable();

WorkerChannel? getWorkerChannel(Logger? logger) =>
    WorkerChannel.deserialize(web.MessageChannel().port1, logger);

final String threadId = Object().hashCode.hex; // unique per event loop
