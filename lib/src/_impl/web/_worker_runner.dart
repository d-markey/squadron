import 'package:web/web.dart' as web;

import '../../worker/worker_request.dart';
import '../xplat/_worker_runner.dart';
import '_patch.dart';

extension JsWorkerRunnerExt on WorkerRunner {
  void handle(web.MessageEvent event) {
    final msg = getMessageEventData(event) as List;
    processMessage(WorkerRequestExt.from(msg));
  }
}
