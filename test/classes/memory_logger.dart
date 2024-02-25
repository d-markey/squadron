import 'package:logger/logger.dart';

import 'test_logger.dart';

class MemoryLogger extends Logger {
  MemoryLogger(List<String> logs, MemoryLogFilter filter)
      : _logs = logs,
        _filter = filter,
        super(filter: filter, output: NoOutput(), printer: EmptyPrinter());

  final MemoryLogFilter _filter;

  Level get level => _filter.level!;
  set level(Level value) => _filter.level = value;

  final List<String> _logs;

  void clear() => _logs.clear();

  @override
  void log(Level level, dynamic message,
      {DateTime? time, Object? error, StackTrace? stackTrace}) {
    if (level.value >= _filter.level!.value) {
      _logs.add(message?.toString() ?? error?.toString() ?? '<no log message>');
    }
    super.log(level, message, time: time, error: error, stackTrace: stackTrace);
  }
}

class MemoryLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => event.level.value >= level!.value;
}
