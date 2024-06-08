import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';

class NotAWorkerService extends Worker {
  NotAWorkerService._(super.entryPoint, [PlatformThreadHook? hook])
      : super(threadHook: hook);

  NotAWorkerService(TestContext context, [PlatformThreadHook? hook])
      : this._(
          context.entryPoints.notAWorker!,
          hook,
        );
}
