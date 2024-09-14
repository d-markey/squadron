import 'converter.dart';

/// This converter converts items in lists and maps **in place**. It avoids
/// creating a copy of the data to hold the conversion result. All items in
/// the list/map are converted at the time the list/map is processed.
class InPlaceConverter extends Converter {
  const InPlaceConverter(this.converter) : super();

  final Converter converter;

  @override
  Cast<T> value<T>() => converter.value<T>();

  @override
  Cast<List<T>> list<T>([Cast<T>? cast]) {
    final op = cast ?? value<T>();
    return Converter.isIdentity<T>(op) ? converter.list<T>(op) : _toList(op);
  }

  @override
  Cast<Map<K, V>> map<K, V>({Cast<K>? kcast, Cast<V>? vcast}) {
    final kop = kcast ?? value<K>(), vop = vcast ?? value<V>();
    return (!Converter.isIdentity<K>(kop) || Converter.isIdentity<V>(vop))
        ? converter.map<K, V>(kcast: kop, vcast: vop)
        : _toMap(vop);
  }

  static Cast<List<T>> _toList<T>(Cast<T> cast) {
    return (x) {
      final y = Converter.toList(x);
      for (var i = y.length - 1; i >= 0; i--) {
        final v = y[i];
        y[i] = (v == null) ? v : cast(v);
      }
      return y.cast<T>();
    };
  }

  Cast<Map<K, V>> _toMap<K, V>(Cast<V> vcast) {
    return (x) {
      x as Map;
      final keys = x.keys.toList();
      for (var i = keys.length - 1; i >= 0; i--) {
        final k = keys[i], v = x[k];
        if (v != null) {
          x[k] = vcast(v);
        }
      }
      return x.cast<K, V>();
    };
  }
}
