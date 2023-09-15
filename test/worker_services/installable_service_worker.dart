import 'package:squadron/squadron.dart';

import 'installable_service.dart';
import 'worker_entry_points.dart';

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
      : super(EntryPoints.installable,
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
