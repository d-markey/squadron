import 'package:squadron/squadron.dart';
import 'package:squadron/version.dart';

mixin SquadronVersion {
  Future<String> getVersion() async => version;

  static const versionCommand = 9999;
}

mixin WorkerVersion on Worker implements SquadronVersion {
  @override
  Future<String> getVersion() => send(SquadronVersion.versionCommand)
      .then(Squadron.converter.value<String>());
}

mixin LocalWorkerVersion on WorkerClient implements SquadronVersion {
  @override
  Future<String> getVersion() => send(SquadronVersion.versionCommand)
      .then(Squadron.converter.value<String>());
}

mixin PoolVersion<W extends WorkerVersion> on WorkerPool<W>
    implements SquadronVersion {
  @override
  Future<String> getVersion() => execute((w) => w.getVersion());
}
