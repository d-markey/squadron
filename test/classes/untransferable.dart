import 'untransferable_native.dart'
    if (dart.library.js) 'untransferable_browser.dart'
    if (dart.library.html) 'untransferable_browser.dart';

dynamic getUntransferable() => getUntransferableImpl();
