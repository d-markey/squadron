import 'package:squadron/squadron.dart';
import 'package:using/using.dart';

extension WorketTestExt<W extends IWorker> on W {
  Future<T> startAndRunTest<T>(Future<T> Function(W) callback) =>
      useAsync<T>((w) async {
        await w.start();
        return callback(w);
      });

  Future<T> runTest<T>(Future<T> Function(W) callback) => useAsync<T>(callback);
}
