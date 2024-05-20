import 'dart:js_interop';

import 'package:web/helpers.dart';
import 'package:web/web.dart' as web;

import '../../worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

@JS()
external web.DedicatedWorkerGlobalScope get self;

void bootstrap(WorkerInitializer initializer, List? command) {
  final com = web.MessageChannel();

  final runner = WorkerRunner((r) {
    r.internalLogger.t(() => 'terminating Web worker');
    com.port1.close();
    com.port2.close();
    self.close();
  });

  com.port1.onmessage = runner.handle.toJS;

  self.onmessage = (web.MessageEvent event) {
    runner.connect(event.data.dartify() as List, com.port2, initializer);
  }.toJS;
}
