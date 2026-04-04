import 'package:squadron/squadron.dart';
import 'package:using/using.dart';

extension IWorketTestExt<W extends IWorker> on W {
  Future<T> startAndRunTest<T>(Future<T> Function(W) callback) =>
      useAsync<T>((w) async {
        await w.start();
        return callback(w);
      });

  Future<T> runTest<T>(Future<T> Function(W) callback) => useAsync<T>(callback);
}

extension WorketTestExt on Worker {
  Duration get upTime => getStats().upTime;
  Duration get idleTime => getStats().idleTime;
  int get activeConnections => getStats().activeConnections;
  int get totalErrors => getStats().totalErrors;
  bool get isStopped => getStats().isStopped;
}
