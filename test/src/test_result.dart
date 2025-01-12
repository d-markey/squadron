import 'dart:async';

enum TestState {
  pending,
  skipped,
  cancelled,
  passed,
  failed,
}

class TestResult {
  TestResult(this.parentPath, this.label)
      : testPath = parentPath.isEmpty ? label : '$parentPath $label';

  final String parentPath;
  final String label;
  final String testPath;

  final _completer = Completer<void>();

  TestState _state = TestState.pending;
  TestState get state => _state;

  bool get isPending => _state == TestState.pending;

  Object? _error;
  Object? get error => _error;

  StackTrace? _stackTrace;
  StackTrace? get stackTrace => _stackTrace;

  bool isMatch(Pattern pattern) => pattern.allMatches(testPath).isNotEmpty;

  void _setState(TestState state, [Object? error, StackTrace? stackTrace]) {
    if (!_completer.isCompleted) {
      _state = state;
      if (state == TestState.failed) {
        _error = error;
        _stackTrace = stackTrace;
      }
      _completer.complete();
    }
  }

  void skip() => Future(() => _setState(TestState.skipped));
  void cancel() => Future(() => _setState(TestState.cancelled));
  void pass() => Future(() => _setState(TestState.passed));
  void fail(Object error, [StackTrace? stackTrace]) =>
      Future(() => _setState(TestState.failed, error, stackTrace));

  Future<void> get done => _completer.future;
}
