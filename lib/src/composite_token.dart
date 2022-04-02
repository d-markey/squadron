import 'cancellable_token.dart';
import 'cancellation_token.dart';
import 'squadron_error.dart';
import 'worker_exception.dart';

/// Composite token cancellation mode
enum CompositeMode {
  /// the [CompositeToken] is cancelled iif all tokens get cancelled
  all,

  /// the [CompositeToken] is cancelled as soon as one of the tokens gets cancelled
  any
}

/// Time-out cancellation tokens used by callers of worker services. The token is cancelled automatically after
/// a period of time indicated by [duration] with a countdown starting only when the task is assigned to a
/// platform worker.
class CompositeToken extends CancellableToken {
  CompositeToken(Iterable<CancellationToken> tokens, this.mode,
      [String? message])
      : assert(tokens.isNotEmpty),
        _tokens = tokens.toList(),
        _signaled = 0,
        super(message) {
    for (var token in _tokens) {
      if (token.cancelled) _signaled++;
      _register(token);
    }
  }

  /// Throws an exception, composite tokens may not be cancelled programmatically.
  @override
  void cancel([CancelledException? exception]) => throw newSquadronError(
      'CompositeToken cannot be cancelled programmatically');

  final CompositeMode mode;

  final List<CancellationToken> _tokens;
  int _signaled;

  /// Called just before processing a [WorkerRequest]. The method actually calls the [start] method for all
  /// tokens registered with this [CompositeToken]. The [onTimeout] callback is mandatory if one of these
  /// tokens is a [TimeOutToken].
  @override
  void start() => _tokens.forEach(_starter);

  void _starter(CancellationToken token) => token.start();

  void _signal() {
    _signaled++;
    _check();
  }

  void _check() {
    if (!cancelled) {
      if ((mode == CompositeMode.any && _signaled >= 1) ||
          (mode == CompositeMode.all && _signaled >= _tokens.length)) {
        if (mode == CompositeMode.all) {
          super.cancel(CancelledException(message: message ?? 'Cancelled'));
        } else {
          super.cancel(_tokens.map((e) => e.exception).firstWhere(
              (e) => e != null,
              orElse: () =>
                  CancelledException(message: message ?? 'Cancelled'))!);
        }
        _tokens.forEach(_unregister);
        super.cancel();
      }
    }
  }

  void _register(CancellationToken token) => token.addListener(_signal);

  void _unregister(CancellationToken token) => token.removeListener(_signal);
}
