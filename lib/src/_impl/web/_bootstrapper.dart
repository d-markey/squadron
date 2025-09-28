import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../typedefs.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';
import '../xplat/_worker_runner.dart';
import '_patch.dart';
import '_worker_runner.dart';

@JS()
external web.DedicatedWorkerGlobalScope get self;

void bootstrap(WorkerInitializer initializer, WorkerRequest? command) {
  final com = web.MessageChannel();

  final runner = WorkerRunner((r) {
    r.internalLogger.t('Terminating Web Worker');
    com.port1.close();
    com.port2.close();
    self.close();
  });

  self.onmessage = (web.MessageEvent e) {
    com.port1.onmessage = runner.handle.toJS;
    runner.connect(WorkerRequestExt.from(e.$dartData!), com.port2, initializer);
  }.toJS;

  // initial message indicating the worker is up and running
  final transfer = JSArray();
  final message = $jsify(WorkerResponse.ready().wrapInPlace(), transfer);
  self.postMessage(message, transfer);
}
