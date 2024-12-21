part of '_channel.dart';

/// [Channel] used to communicate between [web.Worker]s. Creates a
/// [web.MessageChannel] to receive commands on
/// [web.MessageChannel.port2] and forwards them to the worker's [web.MessagePort] via [web.MessageChannel.port1].
final class _WebForwardChannel extends _WebChannel {
  /// [_remote] is the worker's [web.MessagePort], [_com] is the intermediate
  /// message channel
  _WebForwardChannel._(this._remote, this._com, Logger? logger,
      ExceptionManager exceptionManager)
      : super._(_com.port2, logger, exceptionManager) {
    _com.port1.onmessage = _forward.toJS;
  }

  /// [web.MessagePort] to the worker.
  final web.MessagePort _remote;

  /// [web.MessageChannel] used for forwarding messages.
  final web.MessageChannel _com;

  /// Forwards [web.MessageEvent.data] to the worker.
  void _forward(web.MessageEvent e) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }
    try {
      final data = getMessageEventData(e) as List;
      final transfer = Transferables.get(data);
      if (transfer == null || transfer.isEmpty) {
        _remote.postMessage(e.data);
      } else {
        final jsTransfer = transfer.jsify() as JSArray;
        _remote.postMessage(e.data, jsTransfer);
      }
    } catch (ex, st) {
      logger?.e(() => 'Failed to post request $e: $ex');
      throw SquadronErrorExt.create('Failed to post request: $ex', st);
    }
  }

  /// Closes this [Channel], effectively stopping message forwarding.
  @override
  void close() {
    if (!_closed) {
      _com.port1.close();
      _closed = true;
    }
  }
}
