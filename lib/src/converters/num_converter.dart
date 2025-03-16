import '../typedefs.dart';
import 'converter.dart';

final class NumConverter extends Converter {
  const NumConverter();

  static const instance = NumConverter();

  @override
  Cast<T> value<T extends Object>() {
    if (T == int) return _toInt as Cast<T>;
    if (T == double) return _toDbl as Cast<T>;
    return Converter.identity<T>;
  }

  static int _toInt(dynamic x) {
    x as num;
    if (x is int && x.isFinite) return x;
    double y = x.toDouble();
    if (!y.isFinite) return double.nan as int; // intended type error
    final z = y.toInt(), d = y - z;
    if (d != 0) return double.nan as int; // intended type error
    return z;
  }

  static double _toDbl(dynamic x) => (x as num).toDouble();
}
