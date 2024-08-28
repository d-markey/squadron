import '../../cast_helpers.dart' show CastOp;
import '../../exceptions/squadron_error.dart';

class Cast {
  static CastOp<T> toValue<T>() =>
      throw SquadronErrorExt.create('Platform not supported');

  static CastOp<T?> toNullableValue<T>() =>
      throw SquadronErrorExt.create('Platform not supported');

  static CastOp<List<T>> toList<T>([CastOp<T>? op]) =>
      throw SquadronErrorExt.create('Platform not supported');

  static CastOp<Map<K, V>> toMap<K, V>([CastOp<K>? key, CastOp<V>? value]) =>
      throw SquadronErrorExt.create('Platform not supported');

  static bool toBool(dynamic value) => value as bool;
  static bool? toNullableBool(dynamic value) => value as bool?;

  static int toInt(dynamic value) => (value as num).toInt();
  static int? toNullableInt(dynamic value) => (value as num?)?.toInt();

  static double toDbl(dynamic value) => (value as num).toDouble();
  static double? toNullableDbl(dynamic value) => (value as num?)?.toDouble();

  static String toStr(dynamic value) => value as String;
  static String? toNullableStr(dynamic value) => value as String?;

  static T identity<T>(dynamic value) => value as T;
}
