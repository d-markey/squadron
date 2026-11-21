import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/web.dart';
import 'package:meta/meta.dart';

import '../../../build_options.dart';
import '../../../channel.dart';
import '../../../exceptions/exception_manager.dart';
import '../../../exceptions/squadron_error.dart';
import '../../../exceptions/squadron_exception.dart';
import '../../../exceptions/task_terminated_exception.dart';
import '../../../exceptions/worker_exception.dart';
import '../../../tokens/_squadron_cancelation_token.dart';
import '../../../transport/channel_multiplexer.dart';
import '../../../transport/stream_transport.dart';
import '../../../typedefs.dart';
import '../../../worker/worker_message.dart';
import '../../../worker/worker_request.dart';
import '../../../worker/worker_response.dart';
import '_typedefs.dart';
import 'entry_point.dart';

part '_channel_impl.dart';

/// Spawns a child process worker using the [entryPoint] (interpreted as executable path)
/// and initializes communication over `stdin`/`stdout`.
Future<Channel> openChannel(
  IpcEntryPoint entryPoint,
  ExceptionManager exceptionManager,
  Logger? logger,
  List startArguments,
  IpcPlatformThreadHook? hook,
) async {
  if (!BuildOptions.withInternalLogging) {
    logger = null;
  }

  var executable = entryPoint.process;
  final args = <String>[];
  if (executable.endsWith('.dart')) {
    args.add(executable);
    executable = Platform.executable;
  }
  final process = await Process.start(executable, args);

  try {
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      logger?.e('[Sidecar ${process.pid}] [stderr] $line');
    });

    process.exitCode.then((code) {
      logger?.i(
          '[Sidecar ${process.pid}] Worker process exited with exit code: $code');
    });

    final transport =
        StreamTransport(input: process.stdout, output: process.stdin);
    final channel = IpcChannel(transport, process, logger, exceptionManager);

    final startCompleter = Completer<WorkerResponse>();
    channel._pendingRequests[0] = startCompleter;
    channel._postRequest(0, WorkerRequest.start(null, startArguments));

    final startResponse = await startCompleter.future;
    if (startResponse.error != null) {
      throw startResponse.error!;
    }

    if (hook != null) {
      final res = hook.call(process);
      if (res is Future) await res;
    }

    logger?.t('Created Process [${process.pid}]');
    return channel;
  } catch (ex) {
    logger?.e(() => 'Connection to process failed: $ex');
    process.kill();
    rethrow;
  }
}

@internal
int getActiveConnections(Channel channel) => 0;

@internal
void terminateChannel(Channel channel, TaskTerminatedException ex) {
  channel.close();
}

Channel? deserialize(
  IpcPlatformChannel? channelInfo, [
  Logger? logger,
  ExceptionManager? exceptionManager,
]) =>
    null;
