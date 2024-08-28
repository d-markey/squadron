import '../../cast_helpers.dart' show CastOp;

class Cast {
  static CastOp<T> toValue<T>() => identity<T>;

  static CastOp<T?> toNullableValue<T>() => identity<T?>;

  static CastOp<List<T>> toList<T>([CastOp<T>? op]) => _toList();

  static CastOp<Map<K, V>> toMap<K, V>([CastOp<K>? key, CastOp<V>? value]) =>
      _toMap();

  static bool toBool(dynamic value) => value as bool;
  static bool? toNullableBool(dynamic value) => value as bool?;

  static int toInt(dynamic value) => (value as num).toInt();
  static int? toNullableInt(dynamic value) => (value as num?)?.toInt();

  static double toDbl(dynamic value) => (value as num).toDouble();
  static double? toNullableDbl(dynamic value) => (value as num?)?.toDouble();

  static String toStr(dynamic value) => value as String;
  static String? toNullableStr(dynamic value) => value as String?;

  static List<T> Function(dynamic) _toList<T>() => (x) => (x as List).cast<T>();

  static Map<K, V> Function(dynamic) _toMap<K, V>() =>
      (x) => (x as Map).cast<K, V>();

  static T identity<T>(dynamic value) => value as T;
}
