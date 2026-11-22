import 'dart:async';

import 'package:logger/web.dart';

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/task_terminated_exception.dart';
import '../../typedefs.dart';
import '../../worker/entry_point.dart';
import '_typedefs.dart' as impl;
import 'inproc/_channel.dart' as inproc;
import 'inproc/_typedefs.dart';
import 'inproc/entry_point.dart';
import 'ipc/_channel.dart' as ipc;
import 'ipc/_typedefs.dart';
import 'ipc/entry_point.dart';

Future<Channel> openChannel(
  EntryPoint entryPoint,
  ExceptionManager exceptionManager,
  Logger? logger,
  List startArguments,
  impl.PlatformThreadHook? hook,
) {
  switch (entryPoint) {
    case IpcEntryPoint():
      return ipc.openChannel(
        entryPoint,
        exceptionManager,
        logger,
        startArguments,
        hook as IpcPlatformThreadHook?,
      );
    case InProcEntryPoint():
      return inproc.openChannel(
        entryPoint,
        exceptionManager,
        logger,
        startArguments,
        hook as InProcPlatformThreadHook?,
      );
    default:
      throw UnsupportedError(
          'Unsupported native entry point: ${entryPoint.runtimeType}');
  }
}

int getActiveConnections(Channel channel) {
  if (channel is ipc.IpcChannel) {
    return ipc.getActiveConnections(channel);
  } else {
    return inproc.getActiveConnections(channel);
  }
}

void terminateChannel(Channel channel, TaskTerminatedException ex) {
  if (channel is ipc.IpcChannel) {
    ipc.terminateChannel(channel, ex);
  } else {
    inproc.terminateChannel(channel, ex);
  }
}

Channel? deserialize(
  PlatformChannel? channelInfo, [
  Logger? logger,
  ExceptionManager? exceptionManager,
]) {
  if (channelInfo is InProcPlatformChannel) {
    return inproc.deserialize(channelInfo, logger, exceptionManager);
  } else {
    return ipc.deserialize(channelInfo, logger, exceptionManager);
  }
}
