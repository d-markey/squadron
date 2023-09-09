import 'dart:async';

import '../../channel.dart';
import '../../exceptions/squadron_error.dart';
import '../../worker/worker_channel.dart';

typedef EntryPoint = dynamic;
typedef PlatformWorker = dynamic;

typedef PlatformWorkerHook = FutureOr<void> Function(PlatformWorker);

Future<Channel> openChannel(
        EntryPoint entryPoint, String workerId, List startArguments,
        [PlatformWorkerHook? hook]) =>
    throw SquadronErrorExt.create('Platform not supported', StackTrace.current);

Channel? deserializeChannel(dynamic channelInfo) =>
    throw SquadronErrorExt.create('Platform not supported', StackTrace.current);

WorkerChannel? deserializeWorkerChannel(dynamic channelInfo) =>
    throw SquadronErrorExt.create('Platform not supported', StackTrace.current);
