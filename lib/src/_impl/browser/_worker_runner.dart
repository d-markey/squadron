import 'dart:html';

import '../xplat/_worker_runner.dart';

extension JsWorkerRunnerExt on WorkerRunner {
  void handle(MessageEvent event) => processMessage(event.data);
}
