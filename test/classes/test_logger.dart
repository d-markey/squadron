import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';
import 'package:using/using.dart';

class TestLogger extends Logger {
  TestLogger(LogFilter filter)
      : _filter = filter,
        super(
            filter: filter,
            output: NoOutput(),
            printer: EmptyPrinter(),
            level: Level.all);

  final LogFilter _filter;

  Level get level => _filter.level!;

  set level(Level value) => _filter.level = value;
}

class ConsoleTestLogger extends Logger {
  ConsoleTestLogger(LogFilter filter)
      : _filter = filter,
        super(
            filter: filter,
            output: ConsoleOutput(),
            printer: SimplePrinter(),
            level: Level.all);

  final LogFilter _filter;

  Level get level => _filter.level!;
  set level(Level value) => _filter.level = value;
}

class NoOutput extends LogOutput {
  @override
  void output(OutputEvent event) {/* ignore */}
}

class EmptyPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) => const [''];
}

class TempLogger with Releasable {
  TempLogger(this._worker, Logger logger) : _prev = _worker.channelLogger {
    logger.t('>> prev = $_prev / ${_prev.hashCode}');
    logger.t(
        '>> before = ${_worker.channelLogger} / ${_worker.channelLogger.hashCode}');
    _worker.channelLogger = logger;
    logger.t(
        '>> after = ${_worker.channelLogger} / ${_worker.channelLogger.hashCode}');
  }

  final Logger? _prev;
  final IWorker _worker;

  @override
  void release() {
    final logger = _worker.channelLogger!;
    logger.t('<< prev = $_prev / ${_prev.hashCode}');
    logger.t(
        '<< before = ${_worker.channelLogger} / ${_worker.channelLogger.hashCode}');
    _worker.channelLogger = _prev;
    logger.t(
        '<< after = ${_worker.channelLogger} / ${_worker.channelLogger.hashCode}');
    super.release();
  }
}
