class Castor<T> {
  Castor._(this.cast);

  factory Castor.get() {
    if (T == int) {
      return toInt as Castor<T>;
    }
    if (T == double) {
      return toDbl as Castor<T>;
    }
    if (T == List<int>) {
      return toListOfInt as Castor<T>;
    }
    if (T == List<double>) {
      return toListOfDbl as Castor<T>;
    } else {
      return identity<T>();
    }
  }

  final T Function(dynamic) cast;

  static final toInt = Castor<int>._((n) => (n as num).toInt());
  static final toDbl = Castor<double>._((n) => (n as num).toDouble());

  static final toNullableInt = Castor<int?>._((n) => (n as num?)?.toInt());
  static final toNullableDbl =
      Castor<double?>._((n) => (n as num?)?.toDouble());

  static final toListOfInt =
      Castor<List<int>>._((l) => l.map(toInt.cast).toList());
  static final toListOfDbl =
      Castor<List<double>>._((l) => l.map(toDbl.cast).toList());

  static Castor<T> identity<T>() => Castor<T>._((n) => n as T);
}
