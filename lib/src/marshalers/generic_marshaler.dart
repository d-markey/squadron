import 'squadron_marshaler.dart';

/// Base class to abstract `S` in `SquadronMarshaler<T, S>`.
abstract class GenericMarshaler<T> extends SquadronMarshaler<T, dynamic> {
  const GenericMarshaler();
}

/// Provided temporarily for compatibility reasons. See [GenericMarshaler].
@Deprecated('use "GenericMarshaler<T>" instead.')
abstract class GenericMarshaller<T> extends SquadronMarshaller<T, dynamic> {
  const GenericMarshaller();
}
