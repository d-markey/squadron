import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../xplat/_worker_runner.dart';

extension JsWorkerRunnerExt on WorkerRunner {
  void handle(web.MessageEvent event) => processMessage(
        event.data.dartify() as List,
      );
}
