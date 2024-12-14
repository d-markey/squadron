import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

import '../classes/test_logger.dart';

class LogService implements WorkerService {
  LogService() : super() {
    operations.addAll({
      setLevelCommand: (r) => setLevel((r.args[0] as num).toInt()),
      logCommand: (r) => log(),
    });
  }

  final _logger = TestLogger(ProductionFilter());

  void setLevel(int level) {
    _logger.level = Level.values.where((l) => l.value == level).first;
  }

  void log() {
    _logger.t('trace test in worker');
    _logger.d('debug test in worker');
    _logger.i('info test in worker');
    _logger.w('warning test in worker');
    _logger.e('error test in worker');
    _logger.f('fatal test in worker');
  }

  static const setLevelCommand = 1;
  static const logCommand = 2;

  @override
  final Map<int, CommandHandler> operations = {};
}
