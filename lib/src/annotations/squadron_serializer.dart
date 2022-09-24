// import 'dart:typed_data';

abstract class SquadronSerializer<T, S> {
  const SquadronSerializer();

  S marshall(T data);
  T unmarshall(S data);
}

class SerializeWith {
  const SerializeWith(this.serializer);

  final Type serializer;
}
