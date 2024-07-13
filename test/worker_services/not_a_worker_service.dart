import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';

class NotAWorker extends Worker {
  NotAWorker._(super.entryPoint, [PlatformThreadHook? hook])
      : super(threadHook: hook);

  NotAWorker(TestContext context, [PlatformThreadHook? hook])
      : this._(
          context.entryPoints.notAWorker!,
          hook,
        );
}
