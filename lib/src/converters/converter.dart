typedef Cast<T> = T Function(dynamic);

abstract class Converter {
  static bool isIdentity<T>(Cast<T>? cast) =>
      (cast == null) || (cast == identity<T>);

  static T identity<T>(dynamic x) => x as T;

  static T? tryCast<T>(dynamic x) => (x is T) ? x : null;

  // single value
  Cast<T> v<T>();
  Cast<T?> nv<T>();

  // for typed data
  Cast<T> td<T>();
  Cast<T?> ntd<T>();

  // iterable
  Cast<Iterable<T>> i<T>([Cast<T>? cast]);
  Cast<Iterable<T?>> ni<T>([Cast<T?>? cast]);

  // list
  Cast<List<T>> l<T>([Cast<T>? cast]);
  Cast<List<T?>> nl<T>([Cast<T?>? cast]);

  // map
  Cast<Map<K, V>> m<K, V>({Cast<K>? kcast, Cast<V>? vcast});
  Cast<Map<K, V?>> nm<K, V>({Cast<K>? kcast, Cast<V?>? vcast});
}
