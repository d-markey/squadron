/// Base class to serialize/deserialize data of type [T] to a transferable type [S].
abstract class SquadronSerializer<T, S> {
  const SquadronSerializer();

  /// Serialize [data] of type [T] to something of type [S], eg. a `String` or some
  /// binary representation.
  S marshall(T data);

  /// Deserialize a representation of type [S] back to the original data of type
  /// [T]. `unmarshall(marshall(data))` must produce an instance of [T] that is
  /// equivalent to the original instance [data].
  T unmarshall(S data);
}
