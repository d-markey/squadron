import 'dart:async';

import 'package:squadron/squadron.dart';

import 'test_service.dart';

class InstallableService implements WorkerService, ServiceInstaller {
  InstallableService(
      {bool throwOnInstall = false, bool throwOnUninstall = false})
      : _throwOnInstall = throwOnInstall,
        _throwOnUninstall = throwOnUninstall;

  final bool _throwOnInstall;
  final bool _throwOnUninstall;

  bool _installed = false;
  bool _uninstalled = false;

  @override
  FutureOr<void> install() async {
    await Future.delayed(TestService.delay);
    if (_throwOnInstall) {
      Squadron.config('intended failure on install');
      throw WorkerException('intended failure on install');
    }
    _installed = true;
    Squadron.config('service installed successfully');
  }

  @override
  FutureOr<void> uninstall() async {
    await Future.delayed(TestService.delay);
    if (_throwOnUninstall) {
      Squadron.config('''intended failure on uninstall
** depending on the platform, this message may not reach the parent,
** probably because the thread is was killed by the platform before
** the log message was sent to the main thread''');
      throw WorkerException('this exception is intentionally not reported');
    }
    _uninstalled = true;
    Squadron.config('service uninstalled successfully');
  }

  Future<bool> isInstalled() async {
    await Future.delayed(TestService.shortDelay);
    return _installed;
  }

  Future<bool> isUninstalled() async {
    await Future.delayed(TestService.shortDelay);
    return _uninstalled;
  }

  // command IDs
  static const cmdIsInstalled = 1;
  static const cmdIsUninstalled = 2;

  // command IDs --> command implementations
  @override
  Map<int, CommandHandler> get operations => {
        cmdIsInstalled: (r) => isInstalled(),
        cmdIsUninstalled: (r) => isUninstalled(),
      };
}
