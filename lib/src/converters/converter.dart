import '../exceptions/worker_exception.dart';
import '../typedefs.dart';

abstract class Converter {
  const Converter();

  static bool isNumber<T>() => (T == int || T == double);

  static bool isIdentity<T>(Cast<T> cast) => (cast == identity<T>);

  static T identity<T>(dynamic x) => (x is T)
      ? x
      : throw WorkerException(
          'TypeError: ${x.runtimeType} is not a subtype of $T');

  static List<T> _castList<T>(dynamic x) => (x is List<T>)
      ? x
      : ((x is List) ? x.cast<T>() : (x as Iterable).cast<T>().toList());

  static Cast<List<T>> _mapList<T>(Cast<T> op) =>
      (x) => (x as Iterable).map(op).toList();

  static Set<T> _castSet<T>(dynamic x) => (x is Set<T>)
      ? x
      : ((x is Set) ? x.cast<T>() : (x as Iterable).cast<T>().toSet());

  static Cast<Set<T>> _mapSet<T>(Cast<T> op) =>
      (x) => (x as Iterable).map(op).toSet();

  static Map<K, V> _castMap<K, V>(dynamic x) =>
      (x is Map<K, V>) ? x : (x as Map).cast<K, V>();

  static Cast<Map<K, V>> _mapMap<K, V>(Cast<K> kop, Cast<V> vop) =>
      (x) => (x as Map).map((k, v) => MapEntry(kop(k), vop(v)));

  static Cast<T?> allowNull<T extends Object>(Cast<T> op) =>
      isIdentity(op) ? identity<T?> : ((x) => (x == null) ? null : op(x));

  // non-nullable value
  Cast<T> value<T extends Object>();

  // list (of non-nullable T)
  Cast<List<T>> list<T extends Object>([Cast<T>? cast]) {
    final op = cast ?? value<T>();
    return isIdentity<T>(op) ? _castList<T> : _mapList(op);
  }

  // list (of nullable T)
  Cast<List<T?>> nlist<T extends Object>([Cast<T>? cast]) {
    final op = allowNull(cast ?? value<T>());
    return isIdentity<T?>(op) ? _castList<T?> : _mapList(op);
  }

  // set (of non-nullable T)
  Cast<Set<T>> set<T extends Object>([Cast<T>? cast]) {
    final op = cast ?? value<T>();
    return isIdentity<T>(op) ? _castSet<T> : _mapSet<T>(op);
  }

  // set (of nullable T)
  Cast<Set<T?>> nset<T extends Object>([Cast<T>? cast]) {
    var op = allowNull(cast ?? value<T>());
    return isIdentity<T?>(op) ? _castSet<T?> : _mapSet<T?>(op);
  }

  // map (of non-nullable K, V)
  Cast<Map<K, V>> map<K extends Object, V extends Object>(
      {Cast<K>? kcast, Cast<V>? vcast}) {
    final kop = kcast ?? value<K>(), vop = vcast ?? value<V>();
    return (isIdentity<K>(kop) && isIdentity<V>(vop))
        ? _castMap<K, V>
        : _mapMap<K, V>(kop, vop);
  }

  // map (of non-nullable K, nullable V)
  Cast<Map<K, V?>> nmap<K extends Object, V extends Object>(
      {Cast<K>? kcast, Cast<V>? vcast}) {
    final kop = kcast ?? value<K>(), vop = allowNull(vcast ?? value<V>());
    return (isIdentity<K>(kop) && isIdentity<V?>(vop))
        ? _castMap<K, V?>
        : _mapMap<K, V?>(kop, vop);
  }
}
