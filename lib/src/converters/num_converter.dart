import 'cast_converter.dart';
import 'converter.dart';

class NumConverter extends CastConverter {
  const NumConverter();

  static const instance = NumConverter();

  static int _toInt(dynamic x) {
    if (x is int && x.isFinite) return x;
    final y = (x as num).toDouble();
    if (!y.isFinite) return double.minPositive as int; // intended type error
    final z = y.toInt(), d = y - z;
    if (d != 0) return double.minPositive as int; // intended type error
    return z;
  }

  static double _toDbl(dynamic x) => (x as num).toDouble();

  static final Map<Type, Cast> _numCastors = {
    int: _toInt,
    double: _toDbl,
  };

  static int? _toNullableInt(dynamic x) => (x == null) ? null : _toInt(x);

  static double? _toNullableDbl(dynamic x) => (x as num?)?.toDouble();

  static final Map<Type, Cast> _nullableNumCastors = {
    int: _toNullableInt,
    double: _toNullableDbl,
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
