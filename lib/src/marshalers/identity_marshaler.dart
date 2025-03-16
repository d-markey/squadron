import 'marshaling_context.dart';
import 'squadron_marshaler.dart';

/// Identity marshaler.
final class IdentityMarshaler<T> extends SquadronMarshaler<T, T> {
  const IdentityMarshaler();

  @override
  T marshal(T data, [MarshalingContext? context]) => data;

  @override
  T unmarshal(T data, [MarshalingContext? context]) => data;
}
