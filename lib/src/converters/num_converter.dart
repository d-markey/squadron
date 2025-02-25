import 'converter.dart';

final class NumConverter extends Converter {
  const NumConverter();

  static const instance = NumConverter();

  @override
  Cast<T> value<T>() => _numCastors[T] as Cast<T>? ?? Converter.identity<T>;

  static int _toInt(dynamic x) {
    if (x is int && x.isFinite) return x;
    double y = (x as num).toDouble();
    ///////////////////////////// fixed in Squadron 6.2.0
    // if (x is num) {
    //   y = x.toDouble();
    // } else {
    //   // seems like Map<int, V> are received as Map<JSString, V> on wasm
    //   y = double.tryParse(x.toString())!;
    // }
    ///////////////////////////// fixed in Squadron 6.2.0
    if (!y.isFinite) return double.nan as int; // intended type error
    final z = y.toInt(), d = y - z;
    if (d != 0) return double.nan as int; // intended type error
    return z;
  }

  static double _toDbl(dynamic x) => (x as num).toDouble();

  static final Map<Type, Cast> _numCastors = {
    int: _toInt,
    double: _toDbl,
  };
}
