import 'cast_converter.dart';

class NumConverter extends CastConverter {
  const NumConverter();

  static const instance = NumConverter();

  static final Map<Type, Cast> _numCastors = {
    int: (x) => (x as num).toInt(),
    double: (x) => (x as num).toDouble(),
  };

  static final Map<Type, Cast> _nullableNumCastors = {
    int: (x) => (x as num?)?.toInt(),
    double: (x) => (x as num?)?.toDouble(),
  };

  @override
  Cast<T> v<T>() => _numCastors[T] as Cast<T>? ?? super.v<T>();

  @override
  Cast<T?> nv<T>() => _nullableNumCastors[T] as Cast<T?>? ?? super.nv<T>();

  @override
  Cast<Iterable<T>> i<T>([Cast<T>? cast]) =>
      super.i<T>(cast ?? _numCastors[T] as Cast<T>);

  @override
  Cast<Iterable<T?>> ni<T>([Cast<T?>? cast]) =>
      super.ni<T>(cast ?? _nullableNumCastors[T] as Cast<T?>);

  @override
  Cast<List<T>> l<T>([Cast<T>? cast]) =>
      super.l<T>(cast ?? _numCastors[T] as Cast<T>);

  @override
  Cast<List<T?>> nl<T>([Cast<T?>? cast]) =>
      super.nl<T>(cast ?? _nullableNumCastors[T] as Cast<T?>);

  @override
  Cast<Map<K, V>> m<K, V>({Cast<K>? kcast, Cast<V>? vcast}) => super.m<K, V>(
        kcast: kcast ?? _numCastors[K] as Cast<K>?,
        vcast: vcast ?? _numCastors[V] as Cast<V>?,
      );

  @override
  Cast<Map<K, V?>> nm<K, V>({Cast<K>? kcast, Cast<V?>? vcast}) =>
      super.nm<K, V>(
        kcast: kcast ?? _numCastors[K] as Cast<K>?,
        vcast: vcast ?? _nullableNumCastors[V] as Cast<V?>?,
      );
}
