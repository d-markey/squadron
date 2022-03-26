import 'dart:isolate';

import '../channel.dart';
import '../local_worker.dart';
import '../worker_service.dart';

class _VmLocalWorker<W extends WorkerService> extends LocalWorker<W> {
  _VmLocalWorker._(W service) : super(service) {
    final self = this;
    _port.listen((message) {
      processMessage(self, message);
    });
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
