import 'dart:html' as web;

import '../../worker/worker_request.dart';
import '../xplat/_worker_runner.dart';

const $ready = {'ready': true};

extension JsWorkerRunnerExt on WorkerRunner {
  void handle(web.MessageEvent event) =>
      processMessage(WorkerRequest(event.data as List));
}
