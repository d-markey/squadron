import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';

base class MissingWorker extends Worker {
  MissingWorker._(super.entryPoint, [PlatformThreadHook? hook])
      : super(threadHook: hook);

  MissingWorker(TestContext context, [PlatformThreadHook? hook])
      : this._(
          context.entryPoints.missingWorker!,
          hook,
        );
}
