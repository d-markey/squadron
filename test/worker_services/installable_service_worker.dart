import 'package:squadron/squadron.dart';

import '_test_context.dart';
import 'installable_service.dart';

class InstallableWorkerPool extends WorkerPool<InstallableWorker>
    implements InstallableService {
  InstallableWorkerPool(
      {bool throwOnInstall = false,
      bool throwOnUninstall = false,
      ConcurrencySettings? concurrencySettings})
      : super(
            () => InstallableWorker(
                throwOnInstall: throwOnInstall,
                throwOnUninstall: throwOnUninstall),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.threeCpuThreads);

  @override
  void install() {}

  @override
  void uninstall() {}

  @override
  Future<bool> isInstalled() => execute((w) => w.isInstalled());

  @override
  Future<bool> isUninstalled() => execute((w) => w.isUninstalled());
}

class InstallableWorker extends Worker implements InstallableService {
  InstallableWorker(
      {bool throwOnInstall = false, bool throwOnUninstall = false})
      : super(TestContext.entryPoints.installable,
            args: [throwOnInstall, throwOnUninstall]);

  @override
  void install() {}

  @override
  void uninstall() {}

  @override
  Future<bool> isInstalled() => send(InstallableService.cmdIsInstalled);

  @override
  Future<bool> isUninstalled() => send(InstallableService.cmdIsUninstalled);
}
