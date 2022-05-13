import 'dart:html';

import 'package:squadron/squadron.dart';

class Untransferable {}

dynamic getUntransferableImpl() => Untransferable();

WorkerChannel? getWorkerChannelImpl() =>
    WorkerChannel.deserialize(MessageChannel().port1);
