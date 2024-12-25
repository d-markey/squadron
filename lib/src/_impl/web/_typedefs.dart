import 'dart:async';
import 'dart:math';

import 'package:web/web.dart' as web;

import '../../utils.dart';

final threadId = Random.secure().nextInt(0x100000000).hex;

typedef EntryPoint = Uri;
typedef PlatformThread = web.Worker;
typedef PlatformChannel = web.MessagePort;
typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);
