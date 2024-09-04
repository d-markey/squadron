import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import 'installable_service.dart';

class InstallableWorkerPool extends WorkerPool<InstallableWorker>
    implements InstallableService {
  InstallableWorkerPool(TestContext context,
      {bool throwOnInstall = false,
      bool throwOnUninstall = false,
      ConcurrencySettings? concurrencySettings})
      : super(
            () => InstallableWorker._(context,
                throwOnInstall: throwOnInstall,
                throwOnUninstall: throwOnUninstall),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.threeCpuThreads);

  @override
  void install() {
    channelLogger?.d('$runtimeType.install');
  }

  @override
  void uninstall() {
    channelLogger?.d('$runtimeType.uninstall');
  }

  @override
  Future<bool> isInstalled() => execute((w) => w.isInstalled());

  @override
  Future<bool> isUninstalled() => execute((w) => w.isUninstalled());
}

class InstallableWorker extends Worker implements InstallableService {
  InstallableWorker._(TestContext context,
      {bool throwOnInstall = false, bool throwOnUninstall = false})
      : super(context.entryPoints.installable!, args: [
          context.useNumConverter,
          throwOnInstall,
          throwOnUninstall,
        ]);

  InstallableWorker(TestContext context) : this._(context);

  InstallableWorker.throwOnInstall(TestContext context)
      : this._(context, throwOnInstall: true);

  InstallableWorker.throwOnUninstall(TestContext context)
      : this._(context, throwOnUninstall: true);

  @override
  void install() {
    channelLogger?.d('$runtimeType.install');
  }

  @override
  void uninstall() {
    channelLogger?.d('$runtimeType.uninstall');
  }

  @override
  Future<bool> isInstalled() =>
      send(InstallableService.cmdIsInstalled).then(platformConverter.v<bool>());

  @override
  Future<bool> isUninstalled() => send(InstallableService.cmdIsUninstalled)
      .then(platformConverter.v<bool>());
}
