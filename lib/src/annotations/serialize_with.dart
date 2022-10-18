import '../squadron_marshaller.dart';

/// Annotation used to indicate the type of a serializer to be used when
/// marshalling/unmarshalling data to/from a worker service. Package
/// `squadron_builder` will generate appropriate serialization code based
/// on the provided [marshaller].
class SerializeWith {
  const SerializeWith(this.marshaller);

  /// Type or constant instance of the marshaller to use for data serialization
  /// to/from the worker service. The type or instance type must implement
  /// [SquadronMarshaller].
  final dynamic marshaller;
}
