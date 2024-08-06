import 'dart:async';

import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

import '../classes/test_logger.dart';
import 'delays.dart';

class InstallableService implements WorkerService, ServiceInstaller {
  InstallableService(
      {bool throwOnInstall = false, bool throwOnUninstall = false})
      : _throwOnInstall = throwOnInstall,
        _throwOnUninstall = throwOnUninstall;

  Logger? channelLogger = TestLogger(ProductionFilter());

  final bool _throwOnInstall;
  final bool _throwOnUninstall;

  bool _installed = false;
  bool _uninstalled = false;

  @override
  FutureOr<void> install() async {
    await Future.delayed(TestDelays.delay);
    if (_throwOnInstall) {
      channelLogger?.t('intended failure on install');
      throw Exception('this exception is reported');
    }
    _installed = true;
    channelLogger?.t('service installed successfully');
  }

  @override
  FutureOr<void> uninstall() async {
    await Future.delayed(TestDelays.delay);
    if (_throwOnUninstall) {
      channelLogger?.t('intended failure on uninstall');
      throw Exception('this exception is intentionally not reported');
    }
    _uninstalled = true;
    channelLogger?.t('service uninstalled successfully');
  }

  Future<bool> isInstalled() async {
    await Future.delayed(TestDelays.shortDelay);
    return _installed;
  }

  Future<bool> isUninstalled() async {
    await Future.delayed(TestDelays.shortDelay);
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
