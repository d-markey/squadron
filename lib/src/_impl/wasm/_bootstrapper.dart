import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../worker/worker_request.dart';
import '../../worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

@JS()
external web.DedicatedWorkerGlobalScope get self;

void bootstrap(WorkerInitializer initializer, WorkerRequest? command) {
  final com = web.MessageChannel();

  final runner = WorkerRunner((r) {
    r.internalLogger.t('terminating Web Worker');
    com.port1.close();
    com.port2.close();
    self.close();
  });

  com.port1.onmessage = runner.handle.toJS;

  self.onmessage = (web.MessageEvent event) {
    final data = event.data.dartify();
    final req = (data == null) ? null : WorkerRequest(data as List);
    runner.connect(req, com.port2, initializer);
  }.toJS;

  self.postMessage($ready.jsify());
}
