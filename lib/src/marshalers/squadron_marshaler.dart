import 'marshaling_context.dart';

/// Base class to serialize/deserialize data of type [T] to a transferable type [S].
abstract class SquadronMarshaler<T, S> {
  const SquadronMarshaler();

  /// Serialize [data] of type [T] to type [S], eg. a `String` or some binary representation.
  /// `unmarshal(marshal(data))` must produce an instance of [T] that is equivalent to
  /// original instance [data].
  S marshal(T data, [MarshalingContext? context]);

  /// If [data] is `null`, return `null` else call [marshal] with [data] and the [context].
  S? nmarshal(T? data, [MarshalingContext? context]) =>
      (data == null) ? null : marshal(data, context);

  /// Deserialize a representation of type [S] back to the original data of type [T].
  /// `unmarshal(marshal(data))` must produce an instance of [T] that is equivalent to
  /// original instance [data].
  T unmarshal(S data, [MarshalingContext? context]);

  /// If [data] is `null`, return `null` else call [unmarshal] with [data] and the [context].
  T? nunmarshal(S? data, [MarshalingContext? context]) =>
      (data == null) ? null : unmarshal(data, context);
}
