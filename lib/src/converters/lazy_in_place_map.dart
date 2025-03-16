import 'package:meta/meta.dart';

import '../typedefs.dart';

/// Wraps a `Map<dynamic, dynamic>` and a `Cast<V>` converter. Keys in the map
/// must be castable to [K] (`key as K`). Values in the map are converted to [V]
/// on demand i.e. when they are read by the program. Conversion occurs only
/// once for each value and the original `dynamic` value is replaced with the
/// conversion result. If some keys cannot be safely cast to [K], exceptions
/// might occur at runtime, e.g. when reading [keys] or [entries], or calling
/// [map].
@internal
class LazyInPlaceMap<K, V> implements Map<K, V> {
  LazyInPlaceMap(this._data, this._vcast);

  final Map<dynamic, dynamic> _data;
  final Cast<V> _vcast;

  @override
  Iterable<MapEntry<K, V>> get entries =>
      keys.map((k) => MapEntry(k, _get(k) as V));

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Iterable<K> get keys => _data.keys.cast<K>();

  @override
  int get length => _data.length;

  @override
  Iterable<V> get values => _data.keys.map((k) => _get(k) as V);

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
  void forEach(void Function(K key, V value) action) {
    for (var k in _data.keys) {
      action(k as K, _get(k) as V);
    }
  }

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
  String toString() {
    _forceCast();
    return _data.toString();
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

  Map<dynamic, dynamic> _forceCast() {
    var keys = _data.keys.toList();
    for (var i = keys.length - 1; i >= 0; i--) {
      _get(keys[i]);
    }
    return _data;
  }

  V? _get(Object? key) {
    dynamic v = _data[key];
    if (v != null && v is! V) {
      v = _vcast(v);
      _data[key] = v;
    }
    return v;
  }
}
