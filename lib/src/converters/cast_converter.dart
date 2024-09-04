import 'dart:typed_data';

typedef Cast<T> = T Function(dynamic);

class CastConverter {
  const CastConverter();

  static const instance = CastConverter();

  static bool isIdentity<T>(Cast<T>? cast) =>
      (cast == null) || (cast == identity<T>);

  static T identity<T>(dynamic x) => x as T;

  static T? _tryCast<T>(dynamic x) => (x is T) ? x : null;

  Cast<T> v<T>() => identity<T>;

  Cast<T?> nv<T>() => identity<T?>;

  static ByteBuffer? _buffer(dynamic x) => (x == null)
      ? null
      : (x is ByteBuffer)
          ? x
          : (x as TypedData).buffer;

  static Cast<T> _td<T>(T Function(ByteBuffer) b) =>
      (x) => _tryCast<T>(x) ?? b(_buffer(x)!);

  static Cast<T?> _ntd<T>(T Function(ByteBuffer) b) =>
      (x) => (x == null) ? null : (_tryCast<T>(x) ?? b(_buffer(x)!));

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

  Cast<T> td<T>() => _typeDataCastors[T] as Cast<T>;

  Cast<T?> ntd<T>() => _nullableTypeDataCastors[T] as Cast<T?>;

  Cast<Iterable<T>> i<T>([Cast<T>? cast]) => isIdentity<T>(cast)
      ? ((x) => (x as Iterable).cast<T>())
      : ((x) => (x as Iterable).map<T>(v<T>()));

  Cast<Iterable<T?>> ni<T>([Cast<T?>? cast]) => isIdentity<T?>(cast)
      ? ((x) => (x as Iterable).cast<T?>())
      : ((x) => (x as Iterable).map<T?>(nv<T>()));

  Cast<List<T>> l<T>([Cast<T>? cast]) => isIdentity<T>(cast)
      ? ((x) => (x as List).cast<T>())
      : ((x) => (x as List).map<T>(v<T>()).toList());

  Cast<List<T?>> nl<T>([Cast<T?>? cast]) => isIdentity<T?>(cast)
      ? ((x) => (x as List).cast<T?>())
      : ((x) => (x as List).map<T?>(nv<T>()).toList());

  Cast<Map<K, V>> m<K, V>({Cast<K>? kcast, Cast<V>? vcast}) {
    if (isIdentity<K>(kcast) && isIdentity<V>(vcast)) {
      return ((x) => (x as Map).cast<K, V>());
    } else {
      final key = kcast ?? v<K>(), value = vcast ?? v<V>();
      return ((x) => (x as Map).map((k, v) => MapEntry(key(k), value(v))));
    }
  }

  Cast<Map<K, V?>> nm<K, V>({Cast<K>? kcast, Cast<V?>? vcast}) {
    if (isIdentity<K>(kcast) && isIdentity<V?>(vcast)) {
      return ((x) => (x as Map).cast<K, V?>());
    } else {
      final key = kcast ?? v<K>(), value = vcast ?? v<V>();
      return ((x) => (x as Map).map((k, v) => MapEntry(key(k), value(v))));
    }
  }
}
