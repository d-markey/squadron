import 'package:squadron/squadron.dart';

import 'platform_stub.dart'
    if (dart.library.js) 'platform_browser.dart'
    if (dart.library.html) 'platform_browser.dart'
    if (dart.library.io) 'platform_native.dart';

dynamic getUntransferable() => getUntransferableImpl();

WorkerChannel? getWorkerChannel() => getWorkerChannelImpl();
