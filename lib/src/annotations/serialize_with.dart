import '../squadron_serializer.dart';

/// Annotation used to indicate the type of a serializer to be used when
/// marshalling/unmarshalling data to/from a worker service. Package
/// `squadron_builder` will generate appropriate serialization code based
/// on the provided [serializer].
class SerializeWith {
  const SerializeWith(this.serializer);

  /// Type of the serializer to use when marshalling/unmarshalling data to/from
  /// the worker service. This type must implement [SquadronSerializer].
  final Type serializer;
}
