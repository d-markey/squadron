import 'dart:typed_data';

typedef Cast<T> = T Function(dynamic);

abstract base class Converter {
  const Converter();

  static bool isIdentity<T>(Cast<T>? cast) =>
      (cast == null) || (cast == identity<T>);

  static T identity<T>(dynamic x) => x as T;

  static T? tryCast<T>(dynamic x) => (x is T) ? x : null;

  static List<dynamic> toList(dynamic x) =>
      (x is List) ? x : (x as Iterable).toList();

  static Set<dynamic> toSet(dynamic x) =>
      (x is Set) ? x : (x as Iterable).toSet();

  // non-nullable value
  Cast<T> value<T>();

  // nullable value
  Cast<T?> nullable<T>([Cast<T>? cast]) {
    final op = cast ?? value<T>();
    return Converter.isIdentity<T>(op)
        ? value<T?>()
        : (($) => ($ == null) ? null : op($));
  }

  // list
  Cast<List<T>> list<T>([Cast<T>? cast]) {
    final op = cast ?? value<T>();
    return Converter.isIdentity<T>(op)
        ? ((x) => Converter.toList(x).cast<T>())
        : ((x) => Converter.toList(x).map<T>(op).toList());
  }

  // set
  Cast<Set<T>> set<T>([Cast<T>? cast]) {
    final op = list<T>(cast);
    return (x) => op(x).toSet();
  }

  // map
  Cast<Map<K, V>> map<K, V>({Cast<K>? kcast, Cast<V>? vcast}) {
    final kop = kcast ?? value<K>(), vop = vcast ?? value<V>();
    if (Converter.isIdentity<K>(kop) && Converter.isIdentity<V>(vop)) {
      return ((x) => (x as Map).cast<K, V>());
    } else {
      return ((x) => (x as Map).map((k, v) => MapEntry(kop(k), vop(v))));
    }
  }

  // typed data
  Cast<T> typedData<T>() => _typeDataCastors[T] as Cast<T>;

  static ByteBuffer? _buffer<T>(dynamic x) => (x == null)
      ? null
      : (x is ByteBuffer)
          ? x
          : ((x as T) as TypedData).buffer;

  static Cast<T> _td<T>(T Function(ByteBuffer) view) =>
      (x) => Converter.tryCast<T>(x) ?? view(_buffer<T>(x)!);

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
}
