import 'package:logger/web.dart';

class InternalLogger extends Logger {
  InternalLogger()
      : super(
          filter: _LogAllFilter(),
          printer: _DummyPrinter(),
          output: _NoLogOutput(),
        );
}

class _NoLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // Do nothing in this logger (which lives in the worker thread).
    // The log event will be captured and forwarded to the channelLogger (which
    // lives in the main thread).
  }
}

class _DummyPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) =>
      // Logger will ignore log events that produce an empty array.
      // Make sure the array is not empty so the log event is notified
      // through Logger's output callbacks.
      const [''];
}

class _LogAllFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) =>
      // Log everything. It's up to the receiving channelLogger to decide
      // whether the message should be logged or not.
      true;
}
