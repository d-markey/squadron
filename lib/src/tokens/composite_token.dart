import '../exceptions/squadron_error.dart';
import '../exceptions/worker_exception.dart';
import 'cancellation_token.dart';

/// Composite token cancellation mode
enum CompositeMode {
  /// the [CompositeToken] is cancelled iif all tokens get cancelled
  all,

  /// the [CompositeToken] is cancelled as soon as one of the tokens gets cancelled
  any
}

/// Composite cancellation token. The token is cancelled automatically depending on [mode]: with [CompositeMode.any],
/// the composite token is cancelled as soon as when one of the tokens is cancelled. With [CompositeMode.any], the
/// composite token is cancelled when all tokens are cancelled.
class CompositeToken extends CancellationToken {
  CompositeToken(Iterable<CancellationToken> tokens, this.mode,
      [String message = 'The token was cancelled'])
      : assert(tokens.isNotEmpty),
        _tokens = List.unmodifiable(tokens),
        _signaled = 0,
        super(message) {
    for (var token in _tokens) {
      if (token.cancelled) {
        _signaled++;
      } else {
        token.addListener(() {
          _signaled++;
          _check();
        });
      }
    }
    _check();
  }

  final CompositeMode mode;

  final List<CancellationToken> _tokens;
  int _signaled;

  /// Throws an exception, composite tokens may not be cancelled programmatically.
  @override
  void cancel([CancelledException? exception]) => throw SquadronErrorExt.create(
      'CompositeToken cannot be cancelled programmatically',
      StackTrace.current);

  /// Called just before processing a [WorkerRequest]. This method calls the [ensureStarted] method
  /// for all tokens registered with this [CompositeToken].
  @override
  void ensureStarted() {
    for (var token in _tokens) {
      token.ensureStarted();
    }
  }

  void _check() {
    if (!cancelled) {
      if (mode == CompositeMode.any && _signaled >= 1) {
        final exception =
            _tokens.map((t) => t.exception).firstWhere((e) => e != null);
        super.cancel(exception);
      } else if (mode == CompositeMode.all && _signaled >= _tokens.length) {
        super.cancel();
      }
    }
  }
}
