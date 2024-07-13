import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';
import '../../worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_patch.dart';
import '_worker_runner.dart';

@JS()
external web.DedicatedWorkerGlobalScope get self;

void bootstrap(WorkerInitializer initializer, WorkerRequest? command) {
  final url = self.location.href;

  print('[$url] initializing worker...');
  final com = web.MessageChannel();

  final runner = WorkerRunner((r) {
    r.internalLogger.t('$url/terminating Web Worker');
    com.port1.close();
    com.port2.close();
    self.close();
  });

  com.port1.onmessage = runner.handle.toJS;

  self.onmessageerror = (web.ErrorEvent e) {
    getErrorEventError('$url/self.onmessageerror', e);
  }.toJS;

  self.onmessage = (web.MessageEvent e) {
    final msg = getMessageEventData('$url/self.onmessage', e);
    runner
        .connect(WorkerRequestExt.from(msg), com.port2, initializer)
        .then((_) {
      print('[$url] connected...');
    }).catchError((ex, st) {
      print('[$url] connection failed: $ex / $st');
    });
  }.toJS;

  // initial message indicating the worker is up and running
  self.postMessage(WorkerResponse.ready().wrapInPlace().jsify());
  print('[$url] worker ready, waiting for connection...');
}
