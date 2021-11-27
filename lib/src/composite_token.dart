import 'cancellable_token.dart';
import 'cancellation_token.dart';
import 'squadron_exception.dart';
import 'worker_service.dart';

/// Composite token cancellation mode
enum CompositeMode {
  /// the [CompositeToken] is cancelled iif all tokens get cancelled
  all,

  /// the [CompositeToken] is cancelled as soon as one of the tokens gets cancelled
  any
}

/// Composite token cancellation reason
enum CompositeReason {
  /// the token is not cancelled
  none,

  /// no timeout token was cancelled
  cancelled,

  /// at least one timeout token was cancelled
  timeout
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
    _check();
  }

  /// Throws an exception, composite tokens may not be cancelled programmatically.
  @override
  void cancel() => throw SquadronException(
      'A $runtimeType cannot be cancelled programmatically.');

  final CompositeMode mode;

  final List<CancellationToken> _tokens;
  int _signaled;

  /// Called just before processing a [WorkerRequest]. The method actually calls the [start] method for all
  /// tokens registered with this [CompositeToken]. The [onTimeout] callback is mandatory if one of these
  /// tokens is a [TimeOutToken].
  @override
  void start({SquadronCallback? onTimeout}) {
    final starter = _start(onTimeout);
    _tokens.forEach(starter);
  }

  void Function(CancellationToken token) _start(SquadronCallback? onTimeout) =>
      (CancellationToken token) => token.start(onTimeout: onTimeout);

  @override
  void stop() => _tokens.forEach(_stopper);

  void _stopper(CancellationToken token) => token.stop();

  void _signal() {
    _signaled++;
    _check();
  }

  void _check() {
    if (!cancelled) {
      if (mode == CompositeMode.any ||
          (mode == CompositeMode.all && _signaled >= _tokens.length)) {
        _tokens.forEach(_unregister);
        stop();
        super.cancel();
      }
    }
  }

  void _register(CancellationToken token) => token.addListener(_signal);

  void _unregister(CancellationToken token) => token.removeListener(_signal);
}
