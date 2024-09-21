import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import 'installable_service.dart';

base class InstallableWorkerPool extends WorkerPool<InstallableWorker>
    implements InstallableService {
  InstallableWorkerPool(TestContext context,
      {bool throwOnInstall = false,
      bool throwOnUninstall = false,
      ConcurrencySettings? concurrencySettings})
      : super(
            (ExceptionManager exceptionManager) => InstallableWorker._(
                  context,
                  throwOnInstall: throwOnInstall,
                  throwOnUninstall: throwOnUninstall,
                  exceptionManager: exceptionManager,
                ),
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

base class InstallableWorker extends Worker implements InstallableService {
  InstallableWorker._(
    TestContext context, {
    bool throwOnInstall = false,
    bool throwOnUninstall = false,
    ExceptionManager? exceptionManager,
  }) : super(
          context.entryPoints.installable!,
          args: [
            throwOnInstall,
            throwOnUninstall,
          ],
          exceptionManager: exceptionManager,
        );

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
  Future<bool> isInstalled() => send(InstallableService.cmdIsInstalled)
      .then(Squadron.converter.value<bool>());

  @override
  Future<bool> isUninstalled() => send(InstallableService.cmdIsUninstalled)
      .then(Squadron.converter.value<bool>());
}
