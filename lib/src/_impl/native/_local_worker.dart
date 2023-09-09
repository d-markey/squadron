import 'dart:isolate';

import '../../channel.dart';
import '../../local_worker/local_worker.dart';
import '../../worker/worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

class _VmLocalWorker<W extends WorkerService> extends LocalWorker<W> {
  _VmLocalWorker._(W service) : super(service) {
    final runner = WorkerRunner.use(this);
    _port.listen(runner.handle);
  }

  final _port = ReceivePort();
  late Channel? _channel = Channel.deserialize(_port.sendPort);

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
LocalWorker<W> createLocalWorker<W extends WorkerService>(W service) =>
    _VmLocalWorker._(service);
