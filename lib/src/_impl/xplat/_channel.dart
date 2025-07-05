import 'dart:async';

import 'package:logger/web.dart';
import 'package:meta/meta.dart';

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import '../../exceptions/task_terminated_exception.dart';
import "_typedefs.dart";

Future<Channel> openChannel(
  EntryPoint entryPoint,
  ExceptionManager exceptionManager,
  Logger? logger,
  List startArguments,
  PlatformThreadHook? hook,
) =>
    throw SquadronErrorImpl.create('Platform not supported');

@internal
int getActiveConnections(Channel channel) =>
    throw SquadronErrorImpl.create('Platform not supported');

@internal
void terminateChannel(Channel channel, TaskTerminatedException ex) =>
    throw SquadronErrorImpl.create('Platform not supported');

Channel? deserialize(
  PlatformChannel? channelInfo, [
  Logger? logger,
  ExceptionManager? exceptionManager,
]) =>
    throw SquadronErrorImpl.create('Platform not supported');
