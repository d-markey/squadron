import '../marshalers/squadron_marshaler.dart';

/// Annotation used to indicate the type of a serializer to be used when
/// marshaling/unmarshaling data to/from a worker service. Package
/// `squadron_builder` will generate appropriate serialization code based
/// on the provided [marshaler].
class SerializeWith {
  const SerializeWith(this.marshaler);

  /// Type or constant instance of the marshaler to use for data serialization
  /// to/from the worker service. The type or instance type must implement
  /// [SquadronMarshaler].
  final dynamic marshaler;

  /// Provided temporarily for compatibility reasons. See [marshaler].
  @Deprecated('use "marshaler" instead')
  dynamic get marshaller => marshaler;
}
