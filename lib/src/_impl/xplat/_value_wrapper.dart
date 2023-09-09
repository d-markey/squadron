import 'dart:async';

import '../../exceptions/squadron_exception.dart';
import '../../tokens/cancellation_token.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';

/// Wraps a stream of messages coming in from a worker in response to a worker request.
class ValueWrapper<T> {
  /// Constructs a new value wrapper on top of [messages] (stream of messages received from the worker). The
  /// compute operation will be initiated by calling [compute], which will send the [request] to the worker
  /// using [postMethod].
  ValueWrapper(WorkerRequest request,
      {required PostRequest postMethod,
      required Stream messages,
      CancellationToken? token})
      : _request = request,
        _postRequest = postMethod,
        _token = token,
        // _inspectRequest = inspectRequest,
        _completer = Completer<T>() {
    _token?.addListener(_canceller);
    _sub = messages.listen(
      (message) {
        final res = message as List;
        if (!res.unwrapResponse()) {
          return;
        }

        final cancelException = _token?.exception;
        if (cancelException != null) {
          if (!_completer.isCompleted) {
            _completer.completeError(
                cancelException, cancelException.stackTrace);
          }
        } else {
          if (!_completer.isCompleted) {
            final error = res.error;
            if (error != null) {
              _completer.completeError(error, error.stackTrace);
            } else {
              _completer.complete(res.result);
            }
          }
        }
      },
      onError: (e, st) {
        if (!_completer.isCompleted) {
          final error = SquadronException.from(e, st);
          _completer.completeError(error, error.stackTrace);
        }
      },
      cancelOnError: false,
    );
  }

  final WorkerRequest _request;
  final PostRequest _postRequest;
  final CancellationToken? _token;
  // final bool _inspectRequest;

  late final Completer<T> _completer;
  late final StreamSubscription _sub;

  void _canceller() => _postRequest(WorkerRequestImpl.cancel(_token!));

  void _done() {
    _token?.removeListener(_canceller);
    _sub.cancel();
  }

  Future<T> compute() {
    // initiate operation now!
    _postRequest(_request);
    return _completer.future.whenComplete(_done);
  }
}