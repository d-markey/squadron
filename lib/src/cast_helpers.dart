typedef CastOp<T> = T Function(dynamic);

class Cast {
  static CastOp<T> get<T>() {
    if (T == int) {
      return toInt as CastOp<T>;
    } else if (T == double) {
      return toDbl as CastOp<T>;
    } else if ((T == List<int>) || (T == Iterable<int>)) {
      return toListOfInts as CastOp<T>;
    } else if ((T == List<double>) || (T == Iterable<double>)) {
      return toListOfDbls as CastOp<T>;
    } else {
      return identity<T>;
    }
  }

  static int toInt(dynamic value) => (value as num).toInt();
  static int? toNullableInt(dynamic value) => (value as num?)?.toInt();

  static double toDbl(dynamic value) => (value as num).toDouble();
  static double? toNullableDbl(dynamic value) => (value as num?)?.toDouble();

  static List<int> toListOfInts(dynamic list) =>
      (list as Iterable).map(toInt).toList();
  static List<double> toListOfDbls(dynamic list) =>
      (list as Iterable).map(toDbl).toList();

  static T identity<T>(dynamic value) => value as T;
}
