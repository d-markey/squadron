import 'dart:async';

import '../channel.dart';
import '../squadron_error.dart';

typedef EntryPoint = dynamic;
typedef PlatformWorker = dynamic;

typedef PlatformWorkerHook = FutureOr<void> Function(PlatformWorker);

Future<Channel> openChannel(
        EntryPoint entryPoint, String workerId, List startArguments,
        [PlatformWorkerHook? hook]) =>
    throw newSquadronError('Platform not supported', StackTrace.current);

Channel? deserializeChannel(dynamic channelInfo) =>
    throw newSquadronError('Platform not supported', StackTrace.current);

WorkerChannel? deserializeWorkerChannel(dynamic channelInfo) =>
    throw newSquadronError('Platform not supported', StackTrace.current);
