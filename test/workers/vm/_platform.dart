import 'dart:isolate';

import 'package:squadron/squadron.dart';

dynamic getUnsendable() => ReceivePort();

final String threadId = Isolate.current.hashCode.hex;
