import 'squadron_marshaler.dart';

/// Identity marshaler.
class IdentityMarshaler<T> extends SquadronMarshaler<T, T> {
  const IdentityMarshaler();

  @override
  T marshal(T data) => data;

  @override
  T unmarshal(T data) => data;
}

/// Provided temporarily for compatibility reasons. See [IdentityMarshaler].
@Deprecated('use "IdentityMarshaler<T>" instead.')
class IdentityMarshaller<T> extends SquadronMarshaller<T, T> {
  const IdentityMarshaller();
}
