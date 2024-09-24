import '../../squadron.dart';

base class DirectCastConverter extends Converter {
  const DirectCastConverter();

  static const instance = DirectCastConverter();

  @override
  Cast<T> value<T>() => Converter.identity<T>;

  @override
  Cast<T?> nullable<T>([Cast<T>? cast]) => Converter.identity<T?>;

  @override
  Cast<List<T>> list<T>([Cast<T>? cast]) => Converter.identity<List<T>>;

  @override
  Cast<Set<T>> set<T>([Cast<T>? cast]) => Converter.identity<Set<T>>;

  @override
  Cast<Map<K, V>> map<K, V>({Cast<K>? kcast, Cast<V>? vcast}) =>
      Converter.identity<Map<K, V>>;
}
