import '_impl/xplat/_cast_helpers.dart'
    if (dart.library.io) '_impl/native/_cast_helpers.dart'
    if (dart.library.html) '_impl/web/_cast_helpers.dart'
    if (dart.library.js_interop) '_impl/web/_cast_helpers.dart' as impl;

typedef CastOp<T> = T Function(dynamic);

typedef Cast = impl.Cast;
