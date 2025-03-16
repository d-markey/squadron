// import 'dart:typed_data';

// import '../converters/converter.dart';
// import 'squadron_marshaler.dart';

// class TypedDataMarshaler<T extends TypedData>
//     implements SquadronMarshaler<T, ByteBuffer> {
//   const TypedDataMarshaler();

//   @override
//   ByteBuffer marshal(T data) => data.buffer;

//   @override
//   T unmarshal(ByteBuffer data) => _td<T>(_typeDataCastors[T] as Cast<T>)(data);
// }

// Cast<T> _td<T>(T Function(ByteBuffer) view) =>
//     (x) => (x is T) ? x : view(x as ByteBuffer)!;

// final Map<Type, Cast> _typeDataCastors = {
//   ByteData: _td<ByteData>(ByteData.view),
//   Uint8ClampedList: _td<Uint8ClampedList>(Uint8ClampedList.view),
//   Uint8List: _td<Uint8List>(Uint8List.view),
//   Int8List: _td<Int8List>(Int8List.view),
//   Uint16List: _td<Uint16List>(Uint16List.view),
//   Int16List: _td<Int16List>(Int16List.view),
//   Uint32List: _td<Uint32List>(Uint32List.view),
//   Int32List: _td<Int32List>(Int32List.view),
//   Int32x4List: _td<Int32x4List>(Int32x4List.view),
//   Uint64List: _td<Uint64List>(Uint64List.view),
//   Int64List: _td<Int64List>(Int64List.view),
//   Float32List: _td<Float32List>(Float32List.view),
//   Float32x4List: _td<Float32x4List>(Float32x4List.view),
//   Float64List: _td<Float64List>(Float64List.view),
//   Float64x2List: _td<Float64x2List>(Float64x2List.view),
// };
