import 'squadron_marshaler.dart';

/// Base class to abstract `S` in `SquadronMarshaler<T, S>`.
abstract interface class GenericMarshaler<T>
    implements SquadronMarshaler<T, dynamic> {
  const GenericMarshaler();
}
