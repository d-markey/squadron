import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../worker/worker_request.dart';
import '../xplat/_worker_runner.dart';

const $ready = {'ready': true};
const $failed = {'ready': false};

extension JsWorkerRunnerExt on WorkerRunner {
  void handle(web.MessageEvent event) => processMessage(
        WorkerRequest(event.data.dartify() as List),
      );
}
