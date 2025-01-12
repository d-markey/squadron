import '../exceptions/worker_exception.dart';

typedef Cast<T> = T Function(dynamic);

abstract base class Converter {
  const Converter();

  static bool isIdentity<T>(Cast<T> cast) => (cast == identity<T>);

  static T identity<T>(dynamic x) {
    if (x is T) return x;
    throw WorkerException('TypeError: ${x.runtimeType} is not a subtype of $T');
  }

  static List<dynamic> toList(dynamic x) =>
      (x is List) ? x : (x as Iterable).toList();

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
    final op = cast ?? value<T>();
    final toIterable = Converter.isIdentity<T>(op)
        ? ((x) => (x as Iterable).cast<T>())
        : ((x) => (x as Iterable).map(op));
    final toSet = Converter.isIdentity<T>(op)
        ? ((Set x) => x.cast<T>())
        : ((Set x) => x.map(op).toSet());
    return (x) => (x is Set) ? toSet(x) : toIterable(x).toSet();
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
}
