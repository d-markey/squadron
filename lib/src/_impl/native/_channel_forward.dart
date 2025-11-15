part of '_channel.dart';

/// [Channel] used to communicate between [Isolates]s. Creates a
/// [vm.ReceivePort] to receive commands and forwards them to the worker's [vm.SendPort].
final class _VmForwardChannel extends _VmChannel {
  /// [_remote] is the worker's [web.MessagePort], [_com] is the intermediate
  /// message channel
  _VmForwardChannel._(this._remote, this._com, Logger? logger,
      ExceptionManager exceptionManager)
      : super._(_com.sendPort, logger, exceptionManager) {
    _com.listen(_forward);
  }

  /// [web.MessagePort] to the worker.
  final vm.SendPort _remote;

  /// [web.MessageChannel] used for forwarding messages.
  final vm.ReceivePort _com;

  /// Forwards [data] to the worker.
  void _forward(dynamic data) {
    if (_closed.isCompleted) {
      throw SquadronErrorImpl.create('Channel is closed');
    }
    _remote.send(data);
  }

  /// Closes this [Channel], effectively stopping message forwarding.
  @override
  FutureOr<void> close() {
    if (!_closed.isCompleted) {
      _com.close();
      _closed.complete();
    }
    return _closed.future;
  }
}
