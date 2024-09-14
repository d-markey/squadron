import 'dart:math';

import 'converter.dart';

/// This converter converts items in lists and maps **in place**. It avoids
/// creating a copy of the data to hold the conversion result. Additionally,
/// items in the list/map are lazily converted, i.e. only upon accessing them.
class LazyInPlaceConverter extends Converter {
  const LazyInPlaceConverter(this.converter) : super();

  final Converter converter;

  @override
  Cast<T> value<T>() => converter.value<T>();

  @override
  Cast<List<T>> list<T>([Cast<T>? cast]) {
    final op = cast ?? value<T>();
    return Converter.isIdentity<T>(op) ? converter.list<T>(op) : _toList(op);
  }

  @override
  Cast<Map<K, V>> map<K, V>({Cast<K>? kcast, Cast<V>? vcast}) {
    final kop = kcast ?? value<K>(), vop = vcast ?? value<V>();
    return (!Converter.isIdentity<K>(kop) || Converter.isIdentity<V>(vop))
        ? converter.map<K, V>(kcast: kop, vcast: vop)
        : _toMap(vop);
  }

  static Cast<List<T>> _toList<T>(Cast<T> cast) =>
      (x) => _LazyInPlaceList(x, cast);

  static Cast<Map<K, V>> _toMap<K, V>(Cast<V> vcast) =>
      (x) => _LazyInPlaceMap(x, vcast);
}

class _LazyInPlaceList<T> implements List<T> {
  _LazyInPlaceList(this._data, this._cast);

  final List<dynamic> _data;
  final Cast<T> _cast;

  T _get(int idx) {
    dynamic v = _data[idx];
    if (v != null && v is! T) {
      v = _cast(v);
      _data[idx] = v;
    }
    return v;
  }

  Iterable<T> _iterate() sync* {
    for (var i = 0; i < length; i++) {
      yield _get(i);
    }
  }

  List<dynamic> _forceCast() {
    for (var i = length - 1; i >= 0; i--) {
      _get(i);
    }
    return _data;
  }

  @override
  T get first => _get(0);

  @override
  set first(T value) => _data[0] = value;

  @override
  T get last => _get(length - 1);

  @override
  set last(T value) => _data[length - 1] = value;

  @override
  int get length => _data.length;

  @override
  set length(int value) {
    if (value > length) {
      // make sure the list can be extended
      // setting _data.length might succeed because the definition of _data
      // allows nulls even if T is non-nullable
      final test = <T>[];
      test.length = 1;
    }
    _data.length = value;
  }

  @override
  List<T> operator +(List<T> other) {
    final l = length, tl = l + other.length;
    if (tl == l) return _iterate().toList();
    final r = List<T>.filled(tl, other[0]);
    for (var i = 0; i < l; i++) {
      r[i] = _get(i);
    }
    r.setRange(l, tl, other);
    return r;
  }

  @override
  T operator [](int index) => _get(index);

  @override
  void operator []=(int index, T value) => _data[index] = value;

  @override
  void add(T value) => _data.add(value);

  @override
  void addAll(Iterable<T> iterable) => _data.addAll(iterable);

  @override
  bool any(bool Function(T element) test) => _iterate().any(test);

  @override
  Map<int, T> asMap() {
    final r = <int, T>{};
    for (var i = length; i >= 0; i--) {
      r[i] = _get(i);
    }
    return r;
  }

  @override
  List<R> cast<R>() => _forceCast().cast<R>();

  @override
  void clear() => _data.clear();

  @override
  bool contains(Object? element) => _iterate().any((v) => element == v);

  @override
  T elementAt(int index) => _get(index);

  @override
  bool every(bool Function(T element) test) => _iterate().every(test);

  @override
  Iterable<U> expand<U>(Iterable<U> Function(T element) toElements) =>
      _iterate().expand(toElements);

  @override
  void fillRange(int start, int end, [T? fillValue]) =>
      _data.fillRange(start, end, fillValue);

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _iterate().firstWhere(test, orElse: orElse);

  @override
  U fold<U>(U initialValue, U Function(U previousValue, T element) combine) =>
      _iterate().fold(initialValue, combine);

  @override
  Iterable<T> followedBy(Iterable<T> other) => _iterate().followedBy(other);

  @override
  void forEach(void Function(T element) action) => _iterate().forEach(action);

  @override
  Iterable<T> getRange(int start, int end) sync* {
    for (var i = start; i < end; i++) {
      yield _get(i);
    }
  }

  @override
  int indexOf(T element, [int start = 0]) {
    for (var i = start; i < length; i++) {
      if (element == _get(i)) return i;
    }
    return -1;
  }

  @override
  int indexWhere(bool Function(T element) test, [int start = 0]) {
    for (var i = start; i < length; i++) {
      if (test(_get(i))) return i;
    }
    return -1;
  }

  @override
  void insert(int index, T element) => _data.insert(index, element);

  @override
  void insertAll(int index, Iterable<T> iterable) =>
      _data.insertAll(index, iterable);

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Iterator<T> get iterator => _iterate().iterator;

  @override
  String join([String separator = ""]) => _iterate().join(separator);

  @override
  int lastIndexOf(T element, [int? start]) {
    for (var i = start ?? (length - 1); i >= 0; i--) {
      if (element == _get(i)) return i;
    }
    return -1;
  }

  @override
  int lastIndexWhere(bool Function(T element) test, [int? start]) {
    for (var i = start ?? (length - 1); i >= 0; i--) {
      if (test(_get(i))) return i;
    }
    return -1;
  }

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _iterate().lastWhere(test, orElse: orElse);

  @override
  Iterable<U> map<U>(U Function(T e) toElement) => _iterate().map(toElement);

  @override
  T reduce(T Function(T value, T element) combine) =>
      _iterate().reduce(combine);

  @override
  bool remove(Object? value) => _data.remove(value);

  @override
  T removeAt(int index) {
    final v = _get(index);
    _data.removeAt(index);
    return v;
  }

  @override
  T removeLast() {
    final v = _get(length - 1);
    _data.removeLast();
    return v;
  }

  @override
  void removeRange(int start, int end) => _data.removeRange(start, end);

  @override
  void removeWhere(bool Function(T element) test) {
    var i = length;
    while (i >= 0) {
      if (test(_get(i))) {
        final e = i + 1;
        i--;
        while (i >= 0 && test(_get(i))) {
          i--;
        }
        _data.removeRange(i + 1, e);
      } else {
        i--;
      }
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<T> replacements) =>
      _data.replaceRange(start, end, replacements);

  @override
  void retainWhere(bool Function(T element) test) =>
      removeWhere((e) => !test(e));

  @override
  Iterable<T> get reversed sync* {
    for (var i = length - 1; i >= 0; i--) {
      yield _get(i);
    }
  }

  @override
  void setAll(int index, Iterable<T> iterable) => _data.setAll(index, iterable);

  @override
  void setRange(int start, int end, Iterable<T> iterable,
          [int skipCount = 0]) =>
      _data.setRange(start, end, iterable, skipCount);

  @override
  void shuffle([Random? random]) => _data.shuffle(random);

  @override
  T get single => _iterate().single;

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _iterate().singleWhere(test, orElse: orElse);

  @override
  Iterable<T> skip(int count) sync* {
    for (var i = count; i < length; i++) {
      yield _get(i);
    }
  }

  @override
  Iterable<T> skipWhile(bool Function(T value) test) =>
      _iterate().skipWhile(test);

  @override
  void sort([int Function(T a, T b)? compare]) {
    _forceCast();
    if (compare == null) {
      final d = _data.cast<T>();
      d.sort();
      _data.setRange(0, length, d);
    } else {
      _data.sort((a, b) => compare(a as T, b as T));
    }
  }

  @override
  List<T> sublist(int start, [int? end]) =>
      getRange(start, end ?? length).toList();

  @override
  Iterable<T> take(int count) => _iterate().take(count);

  @override
  Iterable<T> takeWhile(bool Function(T value) test) =>
      _iterate().takeWhile(test);

  @override
  List<T> toList({bool growable = true}) =>
      _iterate().toList(growable: growable);

  @override
  Set<T> toSet() => _iterate().toSet();

  @override
  Iterable<T> where(bool Function(T element) test) => _iterate().where(test);

  @override
  Iterable<U> whereType<U>() => _iterate().whereType<U>();
}

class _LazyInPlaceMap<K, V> implements Map<K, V> {
  _LazyInPlaceMap(this._data, this._vcast);

  final Map<dynamic, dynamic> _data;
  final Cast<V> _vcast;

  V? _get(Object? key) {
    dynamic v = _data[key];
    if (v != null && v is! V) {
      v = _vcast(v);
      _data[key] = v;
    }
    return v;
  }

  Map<dynamic, dynamic> _forceCast() {
    var keys = _data.keys.toList();
    for (var i = keys.length - 1; i >= 0; i--) {
      _get(keys[i]);
    }
    return _data;
  }

  @override
  V? operator [](Object? key) => _get(key);

  @override
  void operator []=(K key, V value) => _data[key] = value;

  @override
  void addAll(Map<K, V> other) => _data.addAll(other);

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) =>
      _data.addEntries(newEntries);

  @override
  Map<RK, RV> cast<RK, RV>() => _forceCast().cast<RK, RV>();

  @override
  void clear() => _data.clear();

  @override
  bool containsKey(Object? key) => _data.containsKey(key);

  @override
  bool containsValue(Object? value) => _data.keys.any((k) => value == _get(k));

  @override
  Iterable<MapEntry<K, V>> get entries =>
      keys.map((k) => MapEntry(k, _get(k) as V));

  @override
  void forEach(void Function(K key, V value) action) {
    for (var k in _data.keys) {
      action(k as K, _get(k) as V);
    }
  }

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Iterable<K> get keys => _data.keys.cast<K>();

  @override
  int get length => _data.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) {
    final r = <K2, V2>{}, keys = _data.keys.toList();
    for (var i = keys.length - 1; i >= 0; i--) {
      final k = keys[i], e = convert(k as K, _get(k) as V);
      r[e.key] = e.value;
    }
    return r;
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) =>
      _data.putIfAbsent(key, ifAbsent);

  @override
  V? remove(Object? key) => _data.remove(key);

  @override
  void removeWhere(bool Function(K key, V value) test) {
    final keys = _data.keys.toList();
    for (var i = keys.length - 1; i >= 0; i--) {
      final k = keys[i], v = _get(k);
      if (test(k as K, v as V)) {
        _data.remove(k);
      }
    }
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) =>
      _data.update(key, (v) => (v != null && v is! V) ? _vcast(v) : v,
          ifAbsent: ifAbsent);

  @override
  void updateAll(V Function(K key, V value) update) {
    final keys = _data.keys.toList();
    for (var i = keys.length - 1; i >= 0; i--) {
      final k = keys[i], v = _get(k);
      _data[k] = update(k as K, v as V);
    }
  }

  @override
  Iterable<V> get values sync* {
    final keys = _data.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      yield _get(keys[i]) as V;
    }
  }
}
