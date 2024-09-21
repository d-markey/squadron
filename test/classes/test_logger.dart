import 'package:logger/logger.dart';

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
