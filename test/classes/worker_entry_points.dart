import '../worker_services/worker_entry_points_stub.dart'
    if (dart.library.js) '../sample_js_workers/worker_entry_points.dart'
    if (dart.library.html) '../sample_js_workers/worker_entry_points.dart'
    if (dart.library.io) '../sample_vm_workers/worker_entry_points.dart';

final _entryPoints = entryPoints;

void setEntryPoint(String workerUri, dynamic entryPoint) {
  _entryPoints[workerUri] = entryPoint;
}

dynamic getEntryPoint(String workerUri) => _entryPoints[workerUri]!;
