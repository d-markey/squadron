/// Base class to serialize/deserialize data of type [T] to a transferable type [S].
abstract class SquadronMarshaller<T, S> {
  const SquadronMarshaller();

  /// Serialize [data] of type [T] to type [S], eg. a `String` or some binary representation.
  S marshall(T data);

  /// Deserialize a representation of type [S] back to the original data of type [T].
  /// `unmarshall(marshall(data))` must produce an instance of [T] that is equivalent to
  /// original instance [data].
  T unmarshall(S data);
}

/// Base class to abstract `S` in `SquadronMarshaller<T, S>`.
abstract class GenericMarshaller<T> extends SquadronMarshaller<T, dynamic> {
  const GenericMarshaller();
}

/// Identity marshaller.
class IdentityMarshaller<T> implements SquadronMarshaller<T, T> {
  const IdentityMarshaller();

  @override
  T marshall(T data) => data;

  @override
  T unmarshall(T data) => data;
}
