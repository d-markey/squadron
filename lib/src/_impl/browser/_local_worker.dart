import 'dart:html' as web;

import '../../channel.dart';
import '../../local_worker/local_worker.dart';
import '../../worker/worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

class _JsLocalWorker<W extends WorkerService> extends LocalWorker<W> {
  _JsLocalWorker._(W service) : super(service) {
    final runner = WorkerRunner.use(this);
    _port.port1.onMessage.listen(runner.handle);
  }

  final _port = web.MessageChannel();
  late Channel? _channel = Channel.deserialize(_port.port2);

  @override
  Channel? get channel => _channel;

  @override
  void stop() {
    _port.port1.close();
    _port.port2.close();
    _channel?.close();
    _channel = null;
  }
}

/// Creates a [LocalWorker] on a browser platform.
LocalWorker<W> createLocalWorker<W extends WorkerService>(W service) =>
    _JsLocalWorker._(service);