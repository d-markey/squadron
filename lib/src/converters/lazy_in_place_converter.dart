import 'converter.dart';
import 'lazy_in_place_list.dart';
import 'lazy_in_place_map.dart';

/// This converter converts items in lists and maps **in place**. It avoids
/// creating a copy of the data to hold the conversion result. Additionally,
/// items in the list/map are lazily converted, i.e. only upon accessing them.
final class LazyInPlaceConverter extends Converter {
  const LazyInPlaceConverter(this.converter) : super();

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

  static Cast<List<T>> _toList<T>(Cast<T> cast) =>
      (x) => LazyInPlaceList(x, cast);

  static Cast<Map<K, V>> _toMap<K, V>(Cast<V> vcast) =>
      (x) => LazyInPlaceMap(x, vcast);
}
