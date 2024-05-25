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
            () => InstallableWorker(context,
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
  InstallableWorker(TestContext context,
      {bool throwOnInstall = false, bool throwOnUninstall = false})
      : super(context.entryPoints.installable!,
            args: [throwOnInstall, throwOnUninstall]);

  @override
  void install() {
    channelLogger?.d('$runtimeType.install');
  }

  @override
  void uninstall() {
    channelLogger?.d('$runtimeType.uninstall');
  }

  @override
  Future<bool> isInstalled() => send(InstallableService.cmdIsInstalled);

  @override
  Future<bool> isUninstalled() => send(InstallableService.cmdIsUninstalled);
}
