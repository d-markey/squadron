/// Base class to serialize/deserialize data of type [T] to a transferable type [S].
abstract class SquadronMarshaler<T, S> {
  const SquadronMarshaler();

  /// Provided temporarily for compatibility reasons. See [marshal].
  @Deprecated('use "marshal" instead.')
  S marshall(T data) => marshal(data);

  /// Provided temporarily for compatibility reasons. See [unmarshal].
  @Deprecated('use "unmarshal" instead.')
  T unmarshall(S data) => unmarshal(data);

  /// Serialize [data] of type [T] to type [S], eg. a `String` or some binary representation.
  /// `unmarshal(marshal(data))` must produce an instance of [T] that is equivalent to
  /// original instance [data].
  S marshal(T data);

  /// Deserialize a representation of type [S] back to the original data of type [T].
  /// `unmarshal(marshal(data))` must produce an instance of [T] that is equivalent to
  /// original instance [data].
  T unmarshal(S data);
}

/// Base class to abstract `S` in `SquadronMarshaler<T, S>`.
abstract class GenericMarshaler<T> extends SquadronMarshaler<T, dynamic> {
  const GenericMarshaler();
}

/// Identity marshaler.
class IdentityMarshaler<T> extends SquadronMarshaler<T, T> {
  const IdentityMarshaler();

  @override
  T marshal(T data) => data;

  @override
  T unmarshal(T data) => data;
}

/// Provided temporarily for compatibility reasons. See [SquadronMarshaler].
@Deprecated('use "SquadronMarshaler<T, S>" instead.')
abstract class SquadronMarshaller<T, S> implements SquadronMarshaler<T, S> {
  const SquadronMarshaller() : super();

  @override
  @Deprecated('use "SquadronMarshaler<T, S>.marshal" instead.')
  S marshall(T data) => throw UnimplementedError(
      'SquadronMarshaller is deprecated; use SquadronMarshaler instead.');

  @override
  @Deprecated('use "SquadronMarshaler<T, S>.unmarshal" instead.')
  T unmarshall(S data) => throw UnimplementedError(
      'SquadronMarshaller is deprecated; use SquadronMarshaler instead.');

  @override
  S marshal(T data) => marshall(data);

  @override
  T unmarshal(S data) => unmarshall(data);
}

/// Provided temporarily for compatibility reasons. See [GenericMarshaler].
@Deprecated('use "GenericMarshaler<T>" instead.')
abstract class GenericMarshaller<T> extends SquadronMarshaller<T, dynamic> {
  const GenericMarshaller();
}

/// Provided temporarily for compatibility reasons. See [IdentityMarshaler].
@Deprecated('use "IdentityMarshaler<T>" instead.')
class IdentityMarshaller<T> extends SquadronMarshaller<T, T> {
  const IdentityMarshaller();
}
