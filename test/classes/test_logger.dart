import 'package:logger/logger.dart';

class TestLogger extends Logger {
  TestLogger(TestFilter filter)
      : _filter = filter,
        super(
            filter: filter,
            output: NoOutput(),
            printer: EmptyPrinter(),
            level: Level.all);

  final TestFilter _filter;

  Level get level => _filter.level!;
  set level(Level value) => _filter.level = value;
}

class TestFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => event.level.value >= level!.value;
}

class NoOutput extends LogOutput {
  @override
  void output(OutputEvent event) {/* ignore */}
}

class EmptyPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) => const [''];
}
