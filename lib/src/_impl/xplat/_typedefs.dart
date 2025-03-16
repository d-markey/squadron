import 'dart:async';

import '../../exceptions/squadron_error.dart';

String get threadId => throw SquadronErrorImpl.create('Platform not supported');

typedef EntryPoint = Object;
typedef PlatformThread = Object;
typedef PlatformChannel = Object;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);
