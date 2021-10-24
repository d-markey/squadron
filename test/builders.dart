import 'package:squadron/squadron.dart';

import 'worker_services/builders_stub.dart'
    if (dart.library.js) 'sample_js_workers/builders.dart'
    if (dart.library.html) 'sample_js_workers/builders.dart'
    if (dart.library.io) 'sample_vm_workers/builders.dart';

final _workerBuilders = workerBuilders;

void setWorker<T extends Worker>(T Function([dynamic arg]) value) =>
    _workerBuilders[T] = value;

T getWorker<T extends Worker>([dynamic arg]) => _workerBuilders[T]!(arg) as T;
