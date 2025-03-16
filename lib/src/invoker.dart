import 'package:cancelation_token/cancelation_token.dart';

abstract interface class Invoker {
  /// Sends a command.
  Future<dynamic> send(int command,
      {List args = const [],
      CancelationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false});

  /// Sends a streaming command.
  Stream<dynamic> stream(int command,
      {List args = const [],
      CancelationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false});
}
