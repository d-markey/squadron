import 'dart:async';

import 'package:logger/logger.dart';

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import "../../typedefs.dart";
import '../../worker/worker_channel.dart';

Future<Channel> openChannel(EntryPoint entryPoint,
        ExceptionManager exceptionManager, Logger? logger, List startArguments,
        [PlatformThreadHook? hook]) =>
    throw SquadronErrorExt.create('Platform not supported');

Channel? deserializeChannel(PlatformChannel? channelInfo, Logger? logger,
        ExceptionManager exceptionManager) =>
    throw SquadronErrorExt.create('Platform not supported');

WorkerChannel? deserializeWorkerChannel(
        PlatformChannel? channelInfo, Logger? logger) =>
    throw SquadronErrorExt.create('Platform not supported');
