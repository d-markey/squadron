import 'dart:isolate';

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../local_worker/local_worker.dart';
import '../../worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

class _VmLocalWorker<W extends WorkerService> extends LocalWorker<W> {
  _VmLocalWorker._(super.service, ExceptionManager exceptionManager) {
    final runner = WorkerRunner.use(this);
    _port.listen(runner.handle);
    _channel = Channel.deserialize(
        _port.sendPort, runner.internalLogger, exceptionManager);
  }

  final _port = ReceivePort();
  late Channel? _channel;

  @override
  Channel? get channel => _channel;

  @override
  void stop() {
    _port.close();
    _channel?.close();
    _channel = null;
  }
}

/// Creates a [LocalWorker] on a native platform.
LocalWorker<W> createLocalWorker<W extends WorkerService>(
        W service, ExceptionManager exceptionManager) =>
    _VmLocalWorker._(service, exceptionManager);
