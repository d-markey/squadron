import 'dart:js_interop';

final class RunnerMessage {
  const RunnerMessage._(this.message, [this._tests = const []]);

  RunnerMessage.launch(List<String> tests) : this._(run.message, tests);

  static const cancelled = RunnerMessage._('@@CANCELLED@@');
  static const ready = RunnerMessage._('@@READY@@');
  static const run = RunnerMessage._('@@RUN@@:');

  final String message;
  final List<String> _tests;

  Iterable<String> get tests => _tests.where((_) => true);

  @override
  bool operator ==(Object other) =>
      (other is RunnerMessage) && message == other.message;

  @override
  int get hashCode => message.hashCode;

  JSString get toJS => (message == run.message)
      ? '$message${_tests.join('\n')}'.toJS
      : message.toJS;
}

extension RunnerMessageExt on JSAny? {
  RunnerMessage get toRunnerMessage {
    final msg = dartify()?.toString() ?? '';
    if (msg.startsWith(RunnerMessage.run.message)) {
      return RunnerMessage._(
        RunnerMessage.run.message,
        msg.substring(RunnerMessage.run.message.length).split('\n'),
      );
    } else {
      return RunnerMessage._(msg);
    }
  }
}
