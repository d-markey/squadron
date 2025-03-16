import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../typedefs.dart';

/// Wraps a `List<dynamic>` and a `Cast<E>` converter. Items in the list
/// are converted to `E` on demand i.e. when they are read by the program.
/// Conversion occurs only once for each item and the original `dynamic` item
/// is replaced with the conversion result.
@internal
class LazyInPlaceList<E> implements List<E> {
  LazyInPlaceList(this._data, this._cast);

  final List<dynamic> _data;
  final Cast<E> _cast;

  @override
  E get first => _get(0);

  @override
  set first(E value) => _data[0] = value;

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Iterator<E> get iterator => _iterate().iterator;

  @override
  E get last => _get(length - 1);

  @override
  set last(E value) => _data[length - 1] = value;

  @override
  int get length => _data.length;

  @override
  set length(int value) {
    if (value > length) null as E;
    _data.length = value;
  }

  @override
  Iterable<E> get reversed sync* {
    for (var i = length - 1; i >= 0; i--) {
      yield _get(i);
    }
  }

  @override
  E get single {
    if (isEmpty) throw _ListError.noElement();
    if (length > 1) throw _ListError.tooMany();
    return _get(0);
  }

  @override
  List<E> operator +(List<E> other) {
    final l = length, tl = l + other.length;
    if (tl == l) return toList();
    final r = List<E>.filled(tl, other[0]);
    for (var i = 0; i < l; i++) {
      r[i] = _get(i);
    }
    r.setRange(l, tl, other);
    return r;
  }

  @override
  E operator [](int index) => _get(index);

  @override
  void operator []=(int index, E value) => _data[index] = value;

  @override
  void add(E value) => _data.add(value);

  @override
  void addAll(Iterable<E> iterable) => _data.addAll(iterable);

  @override
  bool any(bool Function(E element) test) {
    final l = length;
    for (var i = 0; i < l; i++) {
      if (test(_get(i))) return true;
    }
    return false;
  }

  @override
  Map<int, E> asMap() {
    final r = <int, E>{}, l = length;
    for (var i = 0; i < l; i++) {
      r[i] = _get(i);
    }
    return r;
  }

  @override
  List<R> cast<R>() => _forceCast().cast<R>();

  @override
  void clear() => _data.clear();

  @override
  bool contains(Object? element) {
    final l = length;
    for (var i = 0; i < l; i++) {
      if (element == _get(i)) return true;
    }
    return false;
  }

  @override
  E elementAt(int index) => _get(index);

  @override
  bool every(bool Function(E element) test) {
    final l = length;
    for (var i = 0; i < l; i++) {
      if (!test(_get(i))) return false;
    }
    return true;
  }

  @override
  Iterable<U> expand<U>(Iterable<U> Function(E element) toElements) sync* {
    final l = length;
    for (var i = 0; i < l; i++) {
      yield* toElements(_get(i));
    }
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) =>
      _data.fillRange(start, end, fillValue);

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) {
    final l = length;
    for (var i = 0; i < l; i++) {
      final v = _get(i);
      if (test(v)) return v;
    }
    if (orElse != null) return orElse();
    throw _ListError.noElement();
  }

  @override
  U fold<U>(U initialValue, U Function(U previousValue, E element) combine) {
    final l = length;
    U res = initialValue;
    for (var i = 0; i < l; i++) {
      res = combine(res, _get(i));
    }
    return res;
  }

  @override
  Iterable<E> followedBy(Iterable<E> other) sync* {
    final l = length;
    for (var i = 0; i < l; i++) {
      yield _get(i);
    }
    yield* other;
  }

  @override
  void forEach(void Function(E element) action) {
    final l = length;
    for (var i = 0; i < l; i++) {
      action(_get(i));
    }
  }

  @override
  Iterable<E> getRange(int start, int end) sync* {
    RangeError.checkValidRange(start, end, length);
    for (var i = start; i < end; i++) {
      yield _get(i);
    }
  }

  @override
  int indexOf(E element, [int start = 0]) {
    final l = length;
    for (var i = start; i < l; i++) {
      if (_get(i) == element) return i;
    }
    return -1;
  }

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) {
    final l = length;
    for (var i = start; i < l; i++) {
      if (test(_get(i))) return i;
    }
    return -1;
  }

  @override
  void insert(int index, E element) => _data.insert(index, element);

  @override
  void insertAll(int index, Iterable<E> iterable) =>
      _data.insertAll(index, iterable);

  @override
  String join([String separator = ""]) {
    final buffer = StringBuffer();
    final l = length;
    if (l > 0) {
      buffer.write(_get(0).toString());
      for (var i = 1; i < l; i++) {
        buffer.write(separator);
        buffer.write(_get(i).toString());
      }
    }
    return buffer.toString();
  }

  @override
  int lastIndexOf(E element, [int? start]) {
    for (var i = start ?? (length - 1); i >= 0; i--) {
      if (element == _get(i)) return i;
    }
    return -1;
  }

  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) {
    for (var i = start ?? (length - 1); i >= 0; i--) {
      if (test(_get(i))) return i;
    }
    return -1;
  }

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) {
    for (var i = length - 1; i >= 0; i--) {
      final v = _get(i);
      if (test(v)) return v;
    }
    if (orElse != null) return orElse();
    throw _ListError.noElement();
  }

  @override
  Iterable<U> map<U>(U Function(E e) toElement) sync* {
    final l = length;
    for (var i = 0; i < l; i++) {
      yield toElement(_get(i));
    }
  }

  @override
  E reduce(E Function(E value, E element) combine) {
    final l = length;
    if (l == 0) throw _ListError.noElement();
    E res = _get(0);
    for (var i = 1; i < l; i++) {
      res = combine(res, _get(i));
    }
    return res;
  }

  @override
  bool remove(Object? value) => _data.remove(value);

  @override
  E removeAt(int index) {
    final v = _get(index);
    _data.removeAt(index);
    return v;
  }

  @override
  E removeLast() {
    final v = _get(length - 1);
    _data.removeLast();
    return v;
  }

  @override
  void removeRange(int start, int end) => _data.removeRange(start, end);

  @override
  void removeWhere(bool Function(E element) test) {
    var i = length - 1;
    while (i >= 0) {
      if (test(_get(i))) {
        final e = i + 1;
        i--;
        while (i >= 0 && test(_get(i))) {
          i--;
        }
        removeRange(i + 1, e);
      } else {
        i--;
      }
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacements) =>
      _data.replaceRange(start, end, replacements);

  @override
  void retainWhere(bool Function(E element) test) =>
      removeWhere((e) => !test(e));

  @override
  void setAll(int index, Iterable<E> iterable) => _data.setAll(index, iterable);

  @override
  void setRange(int start, int end, Iterable<E> iterable,
          [int skipCount = 0]) =>
      _data.setRange(start, end, iterable, skipCount);

  @override
  void shuffle([math.Random? random]) => _data.shuffle(random);

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
    late E res;
    final l = length;
    var found = false;
    for (var i = 0; i < l; i++) {
      final v = _get(i);
      if (test(v)) {
        if (found) throw _ListError.tooMany();
        found = true;
        res = v;
      }
    }
    if (found) return res;
    if (orElse != null) return orElse();
    throw _ListError.noElement();
  }

  @override
  Iterable<E> skip(int count) sync* {
    final l = length;
    for (var i = count; i < l; i++) {
      yield _get(i);
    }
  }

  @override
  Iterable<E> skipWhile(bool Function(E value) test) sync* {
    var i = 0;
    final l = length;
    while (i < l && test(_get(i))) {
      i++;
    }
    while (i < l) {
      yield _get(i);
      i++;
    }
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    _forceCast();
    if (compare == null) {
      final d = _data.cast<E>();
      d.sort();
    } else {
      _data.sort((a, b) => compare(a as E, b as E));
    }
  }

  @override
  List<E> sublist(int start, [int? end]) =>
      getRange(start, end ?? length).toList();

  @override
  Iterable<E> take(int count) sync* {
    final c = math.min(count, length);
    for (var i = 0; i < c; i++) {
      yield _get(i);
    }
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) sync* {
    final l = length;
    for (var i = 0; i < l; i++) {
      final v = _get(i);
      if (!test(v)) break;
      yield v;
    }
  }

  @override
  List<E> toList({bool growable = true}) {
    final l = length;
    if (l == 0) return growable ? [] : const [];
    final res = List.filled(l, _get(0), growable: growable);
    for (var i = 1; i < l; i++) {
      res[i] = _get(i);
    }
    return res;
  }

  @override
  Set<E> toSet() {
    final s = <E>{}, l = length;
    for (var i = 0; i < l; i++) {
      s.add(_get(i));
    }
    return s;
  }

  @override
  String toString() {
    _forceCast();
    return _data.toString();
  }

  @override
  Iterable<E> where(bool Function(E element) test) sync* {
    final l = length;
    for (var i = 0; i < l; i++) {
      final v = _get(i);
      if (test(v)) yield v;
    }
  }

  @override
  Iterable<U> whereType<U>() sync* {
    final l = length;
    for (var i = 0; i < l; i++) {
      final v = _get(i);
      if (v is U) yield v;
    }
  }

  List<dynamic> _forceCast() {
    final l = length;
    for (var i = 0; i < l; i++) {
      _get(i);
    }
    return _data;
  }

  E _get(int idx) {
    dynamic v = _data[idx];
    if (v != null && v is! E) {
      v = _cast(v);
      _data[idx] = v;
    }
    return v;
  }

  Iterable<E> _iterate() sync* {
    final l = length;
    for (var i = 0; i < l; i++) {
      yield _get(i);
    }
  }
}

// copied from dart-sdk\lib\internal\iterable.dart
sealed class _ListError {
  static StateError noElement() => StateError("No element");
  static StateError tooMany() => StateError("Too many elements");
}
