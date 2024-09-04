import 'dart:async';

import 'package:logger/logger.dart';

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import "../../typedefs.dart";

Future<Channel> openChannel(EntryPoint entryPoint,
        ExceptionManager exceptionManager, Logger? logger, List startArguments,
        [PlatformThreadHook? hook]) =>
    throw SquadronErrorExt.create('Platform not supported');

Channel? deserialize(PlatformChannel? channelInfo,
        [Logger? logger, ExceptionManager? exceptionManager]) =>
    throw SquadronErrorExt.create('Platform not supported');
