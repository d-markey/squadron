import '../../cast_helpers.dart' show CastOp;

class Cast {
  static CastOp<T> toValue<T>() {
    if (T == int) {
      return toInt as CastOp<T>;
    } else if (T == double) {
      return toDbl as CastOp<T>;
    } else if (T == bool) {
      return toBool as CastOp<T>;
    } else if (T == String) {
      return toStr as CastOp<T>;
    } else {
      return identity<T>;
    }
  }

  static CastOp<T?> toNullableValue<T>() {
    if (T == int) {
      return toNullableInt as CastOp<T?>;
    } else if (T == double) {
      return toNullableDbl as CastOp<T?>;
    } else if (T == bool) {
      return toNullableBool as CastOp<T?>;
    } else if (T == String) {
      return toNullableStr as CastOp<T?>;
    } else {
      return identity<T?>;
    }
  }

  static CastOp<List<T>> toList<T>([CastOp<T>? op]) =>
      _toList(op ?? toValue<T>());

  static CastOp<Map<K, V>> toMap<K, V>([CastOp<K>? key, CastOp<V>? value]) =>
      _toMap(key ?? toValue<K>(), value ?? toValue<V>());

  static bool toBool(dynamic value) => value as bool;
  static bool? toNullableBool(dynamic value) => value as bool?;

  static int toInt(dynamic value) => (value as num).toInt();
  static int? toNullableInt(dynamic value) => (value as num?)?.toInt();

  static double toDbl(dynamic value) => (value as num).toDouble();
  static double? toNullableDbl(dynamic value) => (value as num?)?.toDouble();

  static String toStr(dynamic value) => value as String;
  static String? toNullableStr(dynamic value) => value as String?;

  static List<T> Function(dynamic) _toList<T>(CastOp<T> op) =>
      (x) => (x as List).map(op).toList();

  static Map<K, V> Function(dynamic) _toMap<K, V>(
          CastOp<K> kop, CastOp<V> vop) =>
      (x) => Map<K, V>.fromEntries(
          (x as Map).entries.map((e) => MapEntry(kop(e.key), vop(e.value))));

  static T identity<T>(dynamic value) => value as T;
}
