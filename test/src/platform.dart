import '_platform_stub.dart'
    if (dart.library.io) '_platform_vm.dart'
    if (dart.library.js_interop) '_platform_web.dart' as impl;

final unsendable = impl.getUnsendable();

void $log(String message) => impl.$log(message);
