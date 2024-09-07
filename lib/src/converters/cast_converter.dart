import 'dart:typed_data';

import 'converter.dart';

class CastConverter implements Converter {
  const CastConverter();

  static const instance = CastConverter();

  @override
  Cast<T> v<T>() => Converter.identity<T>;

  @override
  Cast<T?> nv<T>() => Converter.identity<T?>;

  static ByteBuffer? _buffer<T>(dynamic x) => (x == null)
      ? null
      : (x is ByteBuffer)
          ? x
          : ((x as T) as TypedData).buffer;

  static Cast<T> _td<T>(T Function(ByteBuffer) b) =>
      (x) => Converter.tryCast<T>(x) ?? b(_buffer<T>(x)!);

  static Cast<T?> _ntd<T>(T Function(ByteBuffer) b) => (x) =>
      (x == null) ? null : (Converter.tryCast<T>(x) ?? b(_buffer<T>(x)!));

  static final Map<Type, Cast> _typeDataCastors = {
    ByteData: _td<ByteData>(ByteData.view),
    Uint8ClampedList: _td<Uint8ClampedList>(Uint8ClampedList.view),
    Uint8List: _td<Uint8List>(Uint8List.view),
    Int8List: _td<Int8List>(Int8List.view),
    Uint16List: _td<Uint16List>(Uint16List.view),
    Int16List: _td<Int16List>(Int16List.view),
    Uint32List: _td<Uint32List>(Uint32List.view),
    Int32List: _td<Int32List>(Int32List.view),
    Int32x4List: _td<Int32x4List>(Int32x4List.view),
    Uint64List: _td<Uint64List>(Uint64List.view),
    Int64List: _td<Int64List>(Int64List.view),
    Float32List: _td<Float32List>(Float32List.view),
    Float32x4List: _td<Float32x4List>(Float32x4List.view),
    Float64List: _td<Float64List>(Float64List.view),
    Float64x2List: _td<Float64x2List>(Float64x2List.view),
  };

  static final Map<Type, Cast> _nullableTypeDataCastors = {
    ByteData: _ntd<ByteData>(ByteData.view),
    Uint8ClampedList: _ntd<Uint8ClampedList>(Uint8ClampedList.view),
    Uint8List: _ntd<Uint8List>(Uint8List.view),
    Int8List: _ntd<Int8List>(Int8List.view),
    Uint16List: _ntd<Uint16List>(Uint16List.view),
    Int16List: _ntd<Int16List>(Int16List.view),
    Uint32List: _ntd<Uint32List>(Uint32List.view),
    Int32List: _ntd<Int32List>(Int32List.view),
    Int32x4List: _ntd<Int32x4List>(Int32x4List.view),
    Uint64List: _ntd<Uint64List>(Uint64List.view),
    Int64List: _ntd<Int64List>(Int64List.view),
    Float32List: _ntd<Float32List>(Float32List.view),
    Float32x4List: _ntd<Float32x4List>(Float32x4List.view),
    Float64List: _ntd<Float64List>(Float64List.view),
    Float64x2List: _ntd<Float64x2List>(Float64x2List.view),
  };

  @override
  Cast<T> td<T>() => _typeDataCastors[T] as Cast<T>;

  @override
  Cast<T?> ntd<T>() => _nullableTypeDataCastors[T] as Cast<T?>;

  @override
  Cast<Iterable<T>> i<T>([Cast<T>? cast]) => Converter.isIdentity<T>(cast)
      ? ((x) => (x as Iterable).cast<T>())
      : ((x) => (x as Iterable).map<T>(v<T>()));

  @override
  Cast<Iterable<T?>> ni<T>([Cast<T?>? cast]) => Converter.isIdentity<T?>(cast)
      ? ((x) => (x as Iterable).cast<T?>())
      : ((x) => (x as Iterable).map<T?>(nv<T>()));

  @override
  Cast<List<T>> l<T>([Cast<T>? cast]) => Converter.isIdentity<T>(cast)
      ? ((x) => (x as List).cast<T>())
      : ((x) => (x as List).map<T>(v<T>()).toList());

  @override
  Cast<List<T?>> nl<T>([Cast<T?>? cast]) => Converter.isIdentity<T?>(cast)
      ? ((x) => (x as List).cast<T?>())
      : ((x) => (x as List).map<T?>(nv<T>()).toList());

  @override
  Cast<Map<K, V>> m<K, V>({Cast<K>? kcast, Cast<V>? vcast}) {
    if (Converter.isIdentity<K>(kcast) && Converter.isIdentity<V>(vcast)) {
      return ((x) => (x as Map).cast<K, V>());
    } else {
      final key = kcast ?? v<K>(), value = vcast ?? v<V>();
      return ((x) => (x as Map).map((k, v) => MapEntry(key(k), value(v))));
    }
  }

  @override
  Cast<Map<K, V?>> nm<K, V>({Cast<K>? kcast, Cast<V?>? vcast}) {
    if (Converter.isIdentity<K>(kcast) && Converter.isIdentity<V?>(vcast)) {
      return ((x) => (x as Map).cast<K, V?>());
    } else {
      final key = kcast ?? v<K>(), value = vcast ?? v<V>();
      return ((x) => (x as Map).map((k, v) => MapEntry(key(k), value(v))));
    }
  }
}
