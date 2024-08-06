import 'package:logger/logger.dart';
import 'package:logger/web.dart';

import 'test_logger.dart';

class MemoryLogger extends Logger {
  MemoryLogger(List<String> logs, [LogFilter? filter])
      : _logs = logs,
        _filter = filter ?? ProductionFilter(),
        super(
            filter: filter,
            output: NoOutput(),
            printer: EmptyPrinter(),
            level: Level.all);

  final LogFilter _filter;

  Level get level => _filter.level!;
  set level(Level value) => _filter.level = value;

  final List<String> _logs;

  void clear() => _logs.clear();

  @override
  void log(Level level, dynamic message,
      {DateTime? time, Object? error, StackTrace? stackTrace}) {
    if (level.value >= _filter.level!.value) {
      final msg = (message is Function) ? message() : message;
      _logs.add(msg?.toString() ?? error?.toString() ?? '<no log message>');
    }
    super.log(
      level,
      message,
      time: time ?? DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
