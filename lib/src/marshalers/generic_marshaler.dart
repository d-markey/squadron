import 'squadron_marshaler.dart';

/// Base class to abstract `S` in `SquadronMarshaler<T, S>`.
abstract class GenericMarshaler<T> extends SquadronMarshaler<T, dynamic> {
  const GenericMarshaler();
}
