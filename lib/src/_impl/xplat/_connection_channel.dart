import 'dart:async';

import 'package:logger/logger.dart';

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import '../../tokens/_squadron_cancelation_token.dart';
import '../../typedefs.dart';

class ConnectionChannel implements Channel {
  ConnectionChannel(this.exceptionManager, this.logger);

  @override
  final ExceptionManager exceptionManager;

  @override
  final Logger? logger;

  Never _disconnectedError() =>
      throw SquadronErrorExt.create('Channel is not connected');

  @override
  FutureOr<void> cancelStream(int streamId) => _disconnectedError();

  @override
  FutureOr<void> cancelToken(SquadronCancelationToken? token) =>
      _disconnectedError();

  @override
  FutureOr<void> close() => _disconnectedError();

  @override
  Future<T> sendRequest<T>(
    int command,
    List args, {
    SquadronCancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) =>
      _disconnectedError();

  @override
  Stream<T> sendStreamingRequest<T>(
    int command,
    List args, {
    SquadronCancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) =>
      _disconnectedError();

  @override
  PlatformChannel serialize() => _disconnectedError();

  @override
  Channel share() => _disconnectedError();
}
