/// Base class to serialize/deserialize data of type [T] to a transferable type [S].
abstract class SquadronMarshaler<T, S> {
  const SquadronMarshaler();

  /// Serialize [data] of type [T] to type [S], eg. a `String` or some binary representation.
  /// `unmarshal(marshal(data))` must produce an instance of [T] that is equivalent to
  /// original instance [data].
  S marshal(T data);

  /// Deserialize a representation of type [S] back to the original data of type [T].
  /// `unmarshal(marshal(data))` must produce an instance of [T] that is equivalent to
  /// original instance [data].
  T unmarshal(S data);
}
