import '_impl/xplat/_platform.dart'
    if (dart.library.io) '_impl/native/_platform.dart'
    if (dart.library.html) '_impl/web/_platform.dart'
    if (dart.library.js_interop) '_impl/web/_platform.dart' as impl;

class Squadron {
  static final converter = impl.getPlatformConverter();
  static final platformType = impl.getPlatformType();
}
