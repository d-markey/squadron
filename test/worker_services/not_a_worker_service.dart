import 'package:squadron/squadron.dart';

import '../src/test_context.dart';

base class NotAWorker extends Worker {
  NotAWorker._(super.entryPoint, [PlatformThreadHook? hook])
      : super(threadHook: hook);

  NotAWorker(TestContext context, [PlatformThreadHook? hook])
      : this._(
          context.entryPoints.notAWorker!,
          hook,
        );

  @override
  List? getStartArgs() => null;
}
