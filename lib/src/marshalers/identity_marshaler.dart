import 'squadron_marshaler.dart';

/// Identity marshaler.
final class IdentityMarshaler<T> implements SquadronMarshaler<T, T> {
  const IdentityMarshaler();

  @override
  T marshal(T data) => data;

  @override
  T unmarshal(T data) => data;
}
