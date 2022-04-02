import 'untransferable_stub.dart'
    if (dart.library.js) 'untransferable_browser.dart'
    if (dart.library.html) 'untransferable_browser.dart'
    if (dart.library.io) 'untransferable_native.dart';

dynamic getUntransferable() => getUntransferableImpl();
