import 'dart:async';

import '../../exceptions/squadron_error.dart';

String get threadId => throw SquadronErrorExt.create('Platform not supported');

typedef EntryPoint = dynamic;
typedef PlatformThread = dynamic;
typedef PlatformChannel = dynamic;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);
