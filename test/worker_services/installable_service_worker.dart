import 'package:squadron/squadron.dart';

import '../src/test_context.dart';
import 'installable_service.dart';
import 'squadron_version.dart';

base class InstallableWorkerPool extends WorkerPool<InstallableWorker>
    with PoolVersion<InstallableWorker>
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

base class InstallableWorker extends Worker
    with WorkerVersion
    implements InstallableService {
  InstallableWorker._(
    TestContext context, {
    bool throwOnInstall = false,
    bool throwOnUninstall = false,
    ExceptionManager? exceptionManager,
  })  : args = [
          throwOnInstall,
          throwOnUninstall,
        ],
        super(
          context.entryPoints.installable!,
          exceptionManager: exceptionManager,
        );

  InstallableWorker(TestContext context) : this._(context);

  InstallableWorker.throwOnInstall(TestContext context)
      : this._(context, throwOnInstall: true);

  InstallableWorker.throwOnUninstall(TestContext context)
      : this._(context, throwOnUninstall: true);

  final List args;

  @override
  List getStartArgs() => args;

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
