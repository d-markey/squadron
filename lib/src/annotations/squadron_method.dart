import '../channel.dart';

/// Annotation for service methods to be exposed by workers.
class SquadronMethod {
  const SquadronMethod(
      {this.inspectRequest = false, this.inspectResponse = false});

  /// Indicates whether the contents of the incoming message should be inspected
  /// by Squadron before sending the request to the worker. By default, incoming
  /// messages are not inspected except for the startup message. The purpose of
  /// message inspection is to detect non-base-type data that require transfer of
  /// ownership to the target worker. E.g. if the request data include a [Channel]
  /// object, [inspectRequest] must be set to `true`.
  final bool inspectRequest;

  /// Same as [inspectRequest] but for outgoing messages (response produced by the
  /// worker).
  final bool inspectResponse;
}

const squadronMethod = SquadronMethod();
