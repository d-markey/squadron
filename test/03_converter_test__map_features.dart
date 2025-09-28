// ignore_for_file: file_names

import 'package:squadron/squadron.dart';
import 'package:squadron/src/converters/lazy_in_place_map.dart';
import 'package:test/test.dart';

import 'src/test_context.dart';
import 'src/utils.dart';

void testLazyMaps(TestContext tc) {
  _DataContext<V> $initDataContext<V>(Map data, Cast<V> cast) => (
        lazy: LazyInPlaceMap({...data}, cast),
        ref: Map.fromEntries(data.entries.map(
          (e) => MapEntry(e.key as String, cast(e.value)),
        ))
      );

  tc.group('- Doubles', () {
    final data = Map<dynamic, dynamic>.unmodifiable(
      {'one': 1, 'two': 2, '3dot3': 3.3, 'four': 4, '4dot4': 4.4},
    );

    for (var feature in _dblTests.entries) {
      final dc = $initDataContext(data, _dbl);
      feature.test(tc, dc);
    }
  });

  tc.group('- Nullable doubles', () {
    final data = Map<dynamic, dynamic>.unmodifiable(
      {'one': 1, 'two': 2, '': null, '3dot3': 3.3, 'four': 4, '4dot4': 4.4},
    );

    for (var feature in _ndblTests.entries) {
      final dc = $initDataContext(data, _ndbl);
      feature.test(tc, dc);
    }
  });

  tc.group('- Nullable integers', () {
    final data = Map<dynamic, dynamic>.unmodifiable(
      {'one': 1, 'two': 2, '': null, 'three': 3, 'four': 4, 'five': 5},
    );

    for (var feature in _nintTests.entries) {
      final dc = $initDataContext(data, _nint);
      feature.test(tc, dc);
    }
  });
}

// doubles
final _dx = {'1dot2': 1.2, '1dot3': 1.3, '1dot4': 1.4, '1dot5': 1.5};

final _dblFeats = _Features<double>();
final _dblTests = <String, _FeatureTest<double>>{
  'isEmpty': _dblFeats.isEmpty,
  'isNotEmpty': _dblFeats.isNotEmpty,
  'read length': _dblFeats.getLength,
  'entries': (m) => _dblFeats.entries(m).map((e) => '${e.key} = ${e.value}'),
  'keys': _dblFeats.keys,
  'values': _dblFeats.values,
  'get key': (m) => _dblFeats.getFor(m, 'one'),
  'get key (miss)': (m) => _dblFeats.getFor(m, '!'),
  'set key': (m) => _dblFeats.setFor(m, m.keys.first, _dblSq(m.values.first)),
  'set key (new)': (m) => _dblFeats.setFor(m, _dx.keys.first, _dx.values.first),
  'containsKey': (m) => _dblFeats.containsKey(m, 'one'),
  'containsKey (miss)': (m) => _dblFeats.containsKey(m, '!'),
  'containsValue': (m) => _dblFeats.containsValue(m, m.values.elementAt(2)),
  'containsValue (miss)': (m) => _dblFeats.containsKey(m, -1),
  'cast': _dblFeats.cast<String?, num?>,
  'map': (m) =>
      _dblFeats.map<String?, num?>(m, (k, v) => MapEntry('*$k', _neg(v))),
  'forEach': (m) => _dblFeats.forEach(m, (_, __) {}),
  'addAll': (m) => _dblFeats.addAll(m, _dx),
  'addAll (empty)': (m) => _dblFeats.addAll(m, {}),
  'addEntries': (m) => _dblFeats.addEntries(m, _dx.entries),
  'addEntries (empty)': (m) => _dblFeats.addEntries(m, _Map<double>().entries),
  'putIfAbsent': (m) => _dblFeats.putIfAbsent(m, _dx.keys.first, _nf),
  'putIfAbsent (existing)': (m) => _dblFeats.putIfAbsent(m, m.keys.first, _nf),
  'update': (m) => _dblFeats.update(m, m.keys.first, _dblSq, _nf),
  'update (no default)': (m) => _dblFeats.update(m, m.keys.first, _dblSq, null),
  'update (miss)': (m) => _dblFeats.update(m, _dx.keys.first, _dblSq, _nf),
  'update (miss, no default)': (m) =>
      _dblFeats.update(m, _dx.keys.first, _dblSq, null),
  'updateAll': (m) => _dblFeats.updateAll(m, (k, v) => _dblSq(v)),
  'remove': (m) => _dblFeats.remove(m, 'one'),
  'remove (miss)': (m) => _dblFeats.remove(m, '!'),
  'removeWhere (key)': (m) => _dblFeats.removeWhere(m, (k, v) => k.length > 4),
  'removeWhere (value)': (m) => _dblFeats.removeWhere(m, (k, v) => _isGt3(v)),
  'removeWhere (miss)': (m) => _dblFeats.removeWhere(m, (k, v) => _isNeg(v)),
  'clear': _dblFeats.clear,
  'toString': _dblFeats.getString,
};

final _ndblFeats = _Features<double?>();
final _ndblTests = <String, _FeatureTest<double?>>{
  'isEmpty': _ndblFeats.isEmpty,
  'isNotEmpty': _ndblFeats.isNotEmpty,
  'read length': _ndblFeats.getLength,
  'entries': (m) => _ndblFeats.entries(m).map((e) => '${e.key} = ${e.value}'),
  'keys': _ndblFeats.keys,
  'values': _ndblFeats.values,
  'get key': (m) => _ndblFeats.getFor(m, 'one'),
  'get key (miss)': (m) => _ndblFeats.getFor(m, '!'),
  'set key': (m) => _ndblFeats.setFor(m, m.keys.first, _dblSq(m.values.first)),
  'set key (new)': (m) =>
      _ndblFeats.setFor(m, _dx.keys.first, _dx.values.first),
  'containsKey': (m) => _ndblFeats.containsKey(m, 'one'),
  'containsKey (miss)': (m) => _ndblFeats.containsKey(m, '!'),
  'containsValue': (m) => _ndblFeats.containsValue(m, m.values.elementAt(2)),
  'containsValue (miss)': (m) => _ndblFeats.containsKey(m, -1),
  'cast': _ndblFeats.cast<String?, num?>,
  'map': (m) =>
      _ndblFeats.map<String?, num?>(m, (k, v) => MapEntry('*$k', _neg(v))),
  'forEach': (m) => _ndblFeats.forEach(m, (_, __) {}),
  'addAll': (m) => _ndblFeats.addAll(m, _dx),
  'addAll (empty)': (m) => _ndblFeats.addAll(m, {}),
  'addEntries': (m) => _ndblFeats.addEntries(m, _dx.entries),
  'addEntries (empty)': (m) => _ndblFeats.addEntries(m, _Map<double>().entries),
  'putIfAbsent': (m) => _ndblFeats.putIfAbsent(m, _dx.keys.first, _nf),
  'putIfAbsent (existing)': (m) => _ndblFeats.putIfAbsent(m, m.keys.first, _nf),
  'update': (m) => _ndblFeats.update(m, m.keys.first, _dblSq, _nf),
  'update (no default)': (m) =>
      _ndblFeats.update(m, m.keys.first, _dblSq, null),
  'update (miss)': (m) => _ndblFeats.update(m, _dx.keys.first, _dblSq, _nf),
  'update (miss, no default)': (m) =>
      _ndblFeats.update(m, _dx.keys.first, _dblSq, null),
  'updateAll': (m) => _ndblFeats.updateAll(m, (k, v) => _dblSq(v)),
  'remove': (m) => _ndblFeats.remove(m, 'one'),
  'remove (miss)': (m) => _ndblFeats.remove(m, '!'),
  'removeWhere (key)': (m) => _ndblFeats.removeWhere(m, (k, v) => k.length > 4),
  'removeWhere (value)': (m) => _ndblFeats.removeWhere(m, (k, v) => _isGt3(v)),
  'removeWhere (miss)': (m) => _ndblFeats.removeWhere(m, (k, v) => _isNeg(v)),
  'clear': _ndblFeats.clear,
  'toString': _ndblFeats.getString,
};

// ints
final _ix = {'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15};

final _nintFeats = _Features<int?>();
final _nintTests = <String, _FeatureTest<int?>>{
  'isEmpty': _nintFeats.isEmpty,
  'isNotEmpty': _nintFeats.isNotEmpty,
  'read length': _nintFeats.getLength,
  'entries': (m) => _nintFeats.entries(m).map((e) => '${e.key} = ${e.value}'),
  'keys': _nintFeats.keys,
  'values': _nintFeats.values,
  'get key': (m) => _nintFeats.getFor(m, 'one'),
  'get key (miss)': (m) => _nintFeats.getFor(m, '!'),
  'set key': (m) => _nintFeats.setFor(m, m.keys.first, _intSq(m.values.first)),
  'set key (new)': (m) =>
      _nintFeats.setFor(m, _ix.keys.first, _ix.values.first),
  'containsKey': (m) => _nintFeats.containsKey(m, 'one'),
  'containsKey (miss)': (m) => _nintFeats.containsKey(m, '!'),
  'containsValue': (m) => _nintFeats.containsValue(m, m.values.elementAt(2)),
  'containsValue (miss)': (m) => _nintFeats.containsKey(m, -1),
  'cast': _nintFeats.cast<String?, num?>,
  'map': (m) =>
      _nintFeats.map<String?, num?>(m, (k, v) => MapEntry('*$k', _neg(v))),
  'forEach': (m) => _nintFeats.forEach(m, (_, __) {}),
  'addAll': (m) => _nintFeats.addAll(m, _ix),
  'addAll (empty)': (m) => _nintFeats.addAll(m, {}),
  'addEntries': (m) => _nintFeats.addEntries(m, _ix.entries),
  'addEntries (empty)': (m) => _nintFeats.addEntries(m, _Map<int>().entries),
  'putIfAbsent': (m) => _nintFeats.putIfAbsent(m, _ix.keys.first, _nf),
  'putIfAbsent (existing)': (m) => _nintFeats.putIfAbsent(m, m.keys.first, _nf),
  'update': (m) => _nintFeats.update(m, m.keys.first, _intSq, _nf),
  'update (no default)': (m) =>
      _nintFeats.update(m, m.keys.first, _intSq, null),
  'update (miss)': (m) => _nintFeats.update(m, _dx.keys.first, _intSq, _nf),
  'update (miss, no default)': (m) =>
      _nintFeats.update(m, _dx.keys.first, _intSq, null),
  'updateAll': (m) => _nintFeats.updateAll(m, (k, v) => _intSq(v)),
  'remove': (m) => _nintFeats.remove(m, 'one'),
  'remove (miss)': (m) => _nintFeats.remove(m, '!'),
  'removeWhere (key)': (m) => _nintFeats.removeWhere(m, (k, v) => k.length > 4),
  'removeWhere (value)': (m) => _nintFeats.removeWhere(m, (k, v) => _isGt3(v)),
  'removeWhere (miss)': (m) => _nintFeats.removeWhere(m, (k, v) => _isNeg(v)),
  'clear': _nintFeats.clear,
  'toString': _nintFeats.getString,
};

// helpers
final _dbl = NumConverter.instance.value<double>();
final _ndbl = Converter.allowNull(_dbl);
final _int = NumConverter.instance.value<int>();
final _nint = Converter.allowNull(_int);

bool _isGt3(num? n) => (n != null) && (_dbl(n) > 3);
bool _isNeg(num? n) => (n != null) && (_dbl(n) < 0);

int _intSq(num? n) => _int(n ?? 0) * _int(n ?? 0);
double _dblSq(num? n) => _dbl(n ?? 0) * _dbl(n ?? 0);

double? _neg(num? n) => (n == null) ? null : -_dbl(n);

T _nf<T>() => -1 as T;

typedef _Map<V> = Map<String, V>;
typedef _DataContext<V> = ({LazyInPlaceMap<String, V> lazy, _Map<V> ref});
typedef _FeatureTest<V> = dynamic Function(_Map<V>);

typedef _Action<V> = void Function(String, V);
typedef _Default<V> = V Function();
typedef _Mapper<V, U> = U Function(String, V);
typedef _Updater<V> = V Function(V);

class _Features<V> {
  Iterable<MapEntry<String, V>> entries(_Map<V> m) => m.entries;

  bool isEmpty(_Map<V> m) => m.isEmpty;

  bool isNotEmpty(_Map<V> m) => m.isNotEmpty;

  Iterable<String> keys(_Map<V> m) => m.keys;

  int getLength(_Map<V> m) => m.length;

  Iterable<V> values(_Map<V> m) => m.values;

  V? getFor(_Map<V> m, Object? k) => m[k];

  _Map<V> setFor(_Map<V> m, String k, V v) {
    m[k] = v;
    return m;
  }

  _Map<V> addAll(_Map<V> m, _Map<V> x) => m..addAll(x);

  _Map<V> addEntries(_Map<V> m, Iterable<MapEntry<String, V>> x) =>
      m..addEntries(x);

  Map<RK, RV> cast<RK, RV>(_Map<V> m) => m.cast<RK, RV>();

  _Map<V> clear(_Map<V> m) => m..clear();

  bool containsKey(_Map<V> m, Object? k) => m.containsKey(k);

  bool containsValue(_Map<V> m, Object? v) => m.containsValue(v);

  int forEach(_Map<V> m, _Action<V> a) {
    int n = 0;
    void $a(String k, V v) {
      a(k, v);
      n++;
    }

    m.forEach($a);
    return n;
  }

  Map<K2, V2> map<K2, V2>(_Map<V> m, _Mapper<V, MapEntry<K2, V2>> c) =>
      m.map(c);

  V putIfAbsent(_Map<V> m, String k, _Default<V> d) => m.putIfAbsent(k, d);

  V? remove(_Map<V> m, Object? key) => m.remove(key);

  _Map<V> removeWhere(_Map<V> m, _Mapper<V, bool> t) => m..removeWhere(t);

  String getString(_Map<V> m) => m.toString();

  V update(_Map<V> m, String k, _Updater<V> u, _Default<V>? d) =>
      m.update(k, u, ifAbsent: d);

  _Map<V> updateAll(_Map<V> m, _Mapper<V, V> u) => m..updateAll(u);
}

extension _FeatureTestExt<V> on MapEntry<String, _FeatureTest<V>> {
  void test(TestContext tc, _DataContext<V> data) {
    tc.test('- $key', () {
      expect(data.lazy, data.ref);
      checkOutcome(key, data.lazy, data.ref, value, tc.runnerPlatform);
      expect(data.lazy, data.ref);
    });
  }
}
