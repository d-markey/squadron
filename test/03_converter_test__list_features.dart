// ignore_for_file: file_names

import 'dart:math';

import 'package:squadron/squadron.dart';
import 'package:squadron/src/converters/lazy_in_place_list.dart';
import 'package:test/test.dart';

import 'src/test_context.dart';
import 'src/utils.dart';

void testLazyLists(TestContext tc) {
  _DataContext<T> $initDataContext<T>(List data, Cast<T> cast) =>
      (lazy: LazyInPlaceList([...data], cast), ref: [...data.map(cast)]);

  tc.group('- Doubles', () {
    final data = List<dynamic>.unmodifiable(
      [1, 2, 3, 4, 1.1, 2.2, 3.3, 4.4, 1, 2, 3, 4, 3.3, 2],
    );

    for (var feature in _dblTests.entries) {
      final dc = $initDataContext(data, _dbl);
      feature.check(tc, dc);
    }
  });

  tc.group('- Nullable doubles', () {
    final data = List<dynamic>.unmodifiable(
      [1, 2, null, 4, 1.1, null, 3.3, 4.4, 1, 2, 3, null, 3.3, 2],
    );

    for (var feature in _ndblTests.entries) {
      final dc = $initDataContext(data, _ndbl);
      feature.check(tc, dc);
    }
  });

  tc.group('- Nullable integers', () {
    final data = List<dynamic>.unmodifiable(
      [1, 2, null, 4, 3.toDouble(), null, 2.toDouble(), 4, 1, null, 3],
    );

    for (var feature in _nintTests.entries) {
      final dc = $initDataContext(data, _nint);
      feature.check(tc, dc);
    }
  });
}

// doubles
final _dx = [1.2, 1.3, 1.4, 1.5];

final _dblFeats = _Features<double>();
final _dblTests = <String, _FeatureTest<double>>{
  'isEmpty': _dblFeats.isEmpty,
  'isNotEmpty': _dblFeats.isNotEmpty,
  'read length': _dblFeats.getLength,
  'decrease length': (l) => _dblFeats.decreaseLength(l, 2),
  'increase length': (l) => _dblFeats.increaseLength(l, 2),
  'read single': _dblFeats.getSingle,
  'read first': _dblFeats.getFirst,
  'read last': _dblFeats.getLast,
  'read by index': (l) => _dblFeats.getAt(l, 2),
  'read by index (invalid)': (l) => _dblFeats.getAt(l, -1),
  'set first': (l) => _dblFeats.setFirst(l, _dx.first),
  'set last': (l) => _dblFeats.setLast(l, _dx.first),
  'set by index': (l) => _dblFeats.setAt(l, 2, _dx.first),
  'set by index (invalid)': (l) => _dblFeats.setAt(l, -1, _dx.first),
  'elementAt': (l) => _dblFeats.elementAt(l, 2),
  'elementAt (invalid)': (l) => _dblFeats.elementAt(l, -1),
  'getRange': (l) => _dblFeats.getRange(l, 3, 6),
  'contains': (l) => _dblFeats.contains(l, 2),
  'contains (miss)': (l) => _dblFeats.contains(l, -1),
  'find index': (l) => _dblFeats.indexOf(l, 2, null),
  'find index (skip)': (l) => _dblFeats.indexOf(l, 2, 3),
  'find index (miss)': (l) => _dblFeats.indexOf(l, -1, null),
  'last index': (l) => _dblFeats.lastIndexOf(l, 2, null),
  'last index (skip)': (l) => _dblFeats.lastIndexOf(l, 2, 3),
  'last index (miss)': (l) => _dblFeats.lastIndexOf(l, -1, null),
  'find where': (l) => _dblFeats.indexWhere(l, _isGt3, null),
  'find where (skip)': (l) => _dblFeats.indexWhere(l, _isGt3, 4),
  'find where (miss)': (l) => _dblFeats.indexWhere(l, _isNeg, null),
  'last where': (l) => _dblFeats.lastIndexWhere(l, _isGt3, null),
  'last where (skip)': (l) => _dblFeats.lastIndexWhere(l, _isGt3, 4),
  'last where (miss)': (l) => _dblFeats.lastIndexWhere(l, _isNeg, null),
  'cast': _dblFeats.cast<num?>,
  'toList': _dblFeats.toList,
  'subList (all from start)': (l) => _dblFeats.sublist(l, 0, null),
  'subList (all from mid)': (l) => _dblFeats.sublist(l, 3, null),
  'subList (all from end)': (l) => _dblFeats.sublist(l, l.length - 1, null),
  'subList (start to end)': (l) => _dblFeats.sublist(l, 0, 6),
  'subList (mid to end)': (l) => _dblFeats.sublist(l, 3, 6),
  'subList (end to end)': (l) => _dblFeats.sublist(l, l.length - 1, l.length),
  'subList (invalid range)': (l) => _dblFeats.sublist(l, 4, 3),
  'subList (invalid start)': (l) => _dblFeats.sublist(l, l.length, null),
  'subList (invalid end)': (l) => _dblFeats.sublist(l, 0, l.length + 1),
  'toSet': _dblFeats.toSet,
  'asMap': _dblFeats.asMap,
  'reversed': _dblFeats.reversed,
  'map': (l) => _dblFeats.map(l, _isGt3),
  'expand': (l) => _dblFeats.expand(l, (n) => [n, n * n]),
  'fold': (l) => _dblFeats.fold<double>(l, 0, (s, n) => s + n),
  'reduce': (l) => _dblFeats.reduce(l, (s, n) => s + n),
  'any': (l) => _dblFeats.any(l, _isGt3),
  'any (miss)': (l) => _dblFeats.any(l, _isNeg),
  'every': (l) => _dblFeats.every(l, _isGt3),
  'every (full)': (l) => _dblFeats.every(l, _isNum),
  'skip': (l) => _dblFeats.skip(l, 3),
  'skip while': (l) => _dblFeats.skipWhile(l, _isInt),
  'skip while (miss)': (l) => _dblFeats.skipWhile(l, _isNeg),
  'take': (l) => _dblFeats.take(l, 3),
  'take while': (l) => _dblFeats.takeWhile(l, _isInt).map(_ndbl),
  'take while (miss)': (l) => _dblFeats.takeWhile(l, _isNeg),
  'where': (l) => _dblFeats.where(l, _isGt4),
  'where (miss)': (l) => _dblFeats.where(l, _isNeg),
  'where type': _dblFeats.whereType<num?>,
  'where type (miss)': _dblFeats.whereType<String>,
  'singleWhere': (l) => _dblFeats.singleWhere(l, (n) => n == 2.2, null),
  'singleWhere (match)': (l) => _dblFeats.singleWhere(l, (n) => n == 2.2, _nf),
  'singleWhere (many)': (l) => _dblFeats.singleWhere(l, _isGt3, null),
  'singleWhere (-1 on many)': (l) => _dblFeats.singleWhere(l, _isGt3, _nf),
  'firstWhere': (l) => _dblFeats.firstWhere(l, _isGt4, null),
  'firstWhere (match)': (l) => _dblFeats.firstWhere(l, _isGt4, _nf),
  'firstWhere (miss)': (l) => _dblFeats.firstWhere(l, _isNeg, null),
  'firstWhere (-1 on miss)': (l) => _dblFeats.firstWhere(l, _isNeg, _nf),
  'lastWhere': (l) => _dblFeats.lastWhere(l, _isGt4, null),
  'lastWhere (match)': (l) => _dblFeats.lastWhere(l, _isGt4, _nf),
  'lastWhere (miss)': (l) => _dblFeats.lastWhere(l, _isNeg, null),
  'lastWhere (-1 on miss)': (l) => _dblFeats.lastWhere(l, _isNeg, _nf),
  'forEach': (l) => _dblFeats.forEach(l, (n) {}),
  'concat': (l) => _dblFeats.concat(l, _dx),
  'concat (empty)': (l) => _dblFeats.concat(l, []),
  'add': (l) => _dblFeats.add(l, _dx.first),
  'addAll': (l) => _dblFeats.addAll(l, _dx),
  'followedBy': (l) => _dblFeats.followedBy(l, _dx),
  'fillRange': (l) => _dblFeats.fillRange(l, 3, 5, _dx.first),
  'fillRange (all)': (l) => _dblFeats.fillRange(l, 0, l.length, _dx.first),
  'fillRange (invalid)': (l) => _dblFeats.fillRange(l, -1, l.length, _dx.first),
  'setAll (start)': (l) => _dblFeats.setAll(l, 0, _dx),
  'setAll (mid)': (l) => _dblFeats.setAll(l, 3, _dx),
  'setAll (end)': (l) => _dblFeats.setAll(l, l.length - 1, _dx),
  'setAll (invalid)': (l) => _dblFeats.setAll(l, l.length, _dx),
  'insert (start)': (l) => _dblFeats.insert(l, 0, 1.2),
  'insert (mid)': (l) => _dblFeats.insert(l, 3, 1.2),
  'insert (end)': (l) => _dblFeats.insert(l, l.length - 1, 1.2),
  'insert (invalid)': (l) => _dblFeats.insert(l, l.length, 1.2),
  'insertAll (start)': (l) => _dblFeats.insertAll(l, 0, _dx),
  'insertAll (mid)': (l) => _dblFeats.insertAll(l, 3, _dx),
  'insertAll (end)': (l) => _dblFeats.insertAll(l, l.length - 1, _dx),
  'insertAll (invalid)': (l) => _dblFeats.insertAll(l, l.length, _dx),
  'remove': (l) => _dblFeats.remove(l, 1.1),
  'removeAt': (l) => _dblFeats.removeAt(l, 2),
  'removeLast': _dblFeats.removeLast,
  'removeRange': (l) => _dblFeats.removeRange(l, 3, 6),
  'removeWhere': (l) => _dblFeats.removeWhere(l, _isGt3),
  'retainWhere': (l) => _dblFeats.retainWhere(l, _isGt3),
  'setRange': (l) => _dblFeats.setRange(l, 3, 6, _dx, null),
  'setRange (skip)': (l) => _dblFeats.setRange(l, 3, 6, _dx, 1),
  'replaceRange': (l) => _dblFeats.replaceRange(l, 3, 6, _dx),
  'clear': _dblFeats.clear,
  'sort': (l) => _dblFeats.sort(l, null),
  'sort (reversed)': (l) => _dblFeats.sort(l, (a, b) => b.compareTo(a)),
  'shuffle': (l) => _dblFeats.shuffle(l, Random(_seed)),
  'toString': _dblFeats.getString,
  'join': (l) => _dblFeats.join(l, null),
  'join (dollar)': (l) => _dblFeats.join(l, ' \$ '),
};

final _ndblFeats = _Features<double?>();
final _ndblTests = <String, _FeatureTest<double?>>{
  'isEmpty': _ndblFeats.isEmpty,
  'isNotEmpty': _ndblFeats.isNotEmpty,
  'read length': _ndblFeats.getLength,
  'decrease length': (l) => _ndblFeats.decreaseLength(l, 2),
  'increase length': (l) => _ndblFeats.increaseLength(l, 2),
  'read single': _ndblFeats.getSingle,
  'read first': _ndblFeats.getFirst,
  'read last': _ndblFeats.getLast,
  'read by index': (l) => _ndblFeats.getAt(l, 2),
  'read by index (invalid)': (l) => _ndblFeats.getAt(l, -1),
  'set first': (l) => _ndblFeats.setFirst(l, _dx.first),
  'set last': (l) => _ndblFeats.setLast(l, _dx.first),
  'set by index': (l) => _ndblFeats.setAt(l, 2, _dx.first),
  'set by index (invalid)': (l) => _ndblFeats.setAt(l, -1, _dx.first),
  'elementAt': (l) => _ndblFeats.elementAt(l, 2),
  'elementAt (invalid)': (l) => _ndblFeats.elementAt(l, -1),
  'getRange': (l) => _ndblFeats.getRange(l, 3, 6),
  'contains': (l) => _ndblFeats.contains(l, 2),
  'contains (miss)': (l) => _ndblFeats.contains(l, -1),
  'find index': (l) => _ndblFeats.indexOf(l, 2, null),
  'find index (skip)': (l) => _ndblFeats.indexOf(l, 2, 3),
  'find index (miss)': (l) => _ndblFeats.indexOf(l, -1, null),
  'last index': (l) => _ndblFeats.lastIndexOf(l, 2, null),
  'last index (skip)': (l) => _ndblFeats.lastIndexOf(l, 2, 3),
  'last index (miss)': (l) => _ndblFeats.lastIndexOf(l, -1, null),
  'find where': (l) => _ndblFeats.indexWhere(l, _isGt3, null),
  'find where (skip)': (l) => _ndblFeats.indexWhere(l, _isGt3, 4),
  'find where (miss)': (l) => _ndblFeats.indexWhere(l, _isNeg, null),
  'last where': (l) => _ndblFeats.lastIndexWhere(l, _isGt3, null),
  'last where (skip)': (l) => _ndblFeats.lastIndexWhere(l, _isGt3, 4),
  'last where (miss)': (l) => _ndblFeats.lastIndexWhere(l, _isNeg, null),
  'cast': _ndblFeats.cast<num?>,
  'toList': _ndblFeats.toList,
  'subList (all from start)': (l) => _ndblFeats.sublist(l, 0, null),
  'subList (all from mid)': (l) => _ndblFeats.sublist(l, 3, null),
  'subList (all from end)': (l) => _ndblFeats.sublist(l, l.length - 1, null),
  'subList (start to end)': (l) => _ndblFeats.sublist(l, 0, 6),
  'subList (mid to end)': (l) => _ndblFeats.sublist(l, 3, 6),
  'subList (end to end)': (l) => _ndblFeats.sublist(l, l.length - 1, l.length),
  'subList (invalid range)': (l) => _ndblFeats.sublist(l, 4, 3),
  'subList (invalid start)': (l) => _ndblFeats.sublist(l, l.length, null),
  'subList (invalid end)': (l) => _ndblFeats.sublist(l, 0, l.length + 1),
  'toSet': _ndblFeats.toSet,
  'asMap': _ndblFeats.asMap,
  'reversed': _ndblFeats.reversed,
  'map': (l) => _ndblFeats.map(l, _isGt3),
  'expand': (l) => _ndblFeats.expand(l, (n) => [n, n == null ? null : n * n]),
  'fold': (l) => _ndblFeats.fold<double>(l, 0, (s, n) => s + (n ?? 0)),
  'reduce': (l) => _ndblFeats.reduce(l, (s, n) => (s ?? 0) + (n ?? 0)),
  'any': (l) => _ndblFeats.any(l, _isGt3),
  'any (miss)': (l) => _ndblFeats.any(l, _isNeg),
  'every': (l) => _ndblFeats.every(l, _isGt3),
  'every (full)': (l) => _ndblFeats.every(l, _isNum),
  'skip': (l) => _ndblFeats.skip(l, 3),
  'skip while': (l) => _ndblFeats.skipWhile(l, _isInt),
  'skip while (miss)': (l) => _ndblFeats.skipWhile(l, _isNeg),
  'take': (l) => _ndblFeats.take(l, 3),
  'take while': (l) => _ndblFeats.takeWhile(l, _isInt),
  'take while (miss)': (l) => _ndblFeats.takeWhile(l, _isNeg),
  'where': (l) => _ndblFeats.where(l, _isGt4),
  'where (miss)': (l) => _ndblFeats.where(l, _isNeg),
  'where type': _ndblFeats.whereType<Null>,
  'where type (miss)': _ndblFeats.whereType<String>,
  'singleWhere': (l) => _ndblFeats.singleWhere(l, (n) => n == 2.2, null),
  'singleWhere (match)': (l) => _ndblFeats.singleWhere(l, (n) => n == 2.2, _nf),
  'singleWhere (many)': (l) => _ndblFeats.singleWhere(l, _isGt3, null),
  'singleWhere (-1 on many)': (l) => _ndblFeats.singleWhere(l, _isGt3, _nf),
  'firstWhere': (l) => _ndblFeats.firstWhere(l, _isGt4, null),
  'firstWhere (match)': (l) => _ndblFeats.firstWhere(l, _isGt4, _nf),
  'firstWhere (miss)': (l) => _ndblFeats.firstWhere(l, _isNeg, null),
  'firstWhere (-1 on miss)': (l) => _ndblFeats.firstWhere(l, _isNeg, _nf),
  'lastWhere': (l) => _ndblFeats.lastWhere(l, _isGt4, null),
  'lastWhere (match)': (l) => _ndblFeats.lastWhere(l, _isGt4, _nf),
  'lastWhere (miss)': (l) => _ndblFeats.lastWhere(l, _isNeg, null),
  'lastWhere (-1 on miss)': (l) => _ndblFeats.lastWhere(l, _isNeg, _nf),
  'forEach': (l) => _ndblFeats.forEach(l, (n) {}),
  'concat': (l) => _ndblFeats.concat(l, _dx),
  'concat (empty)': (l) => _ndblFeats.concat(l, []),
  'add': (l) => _ndblFeats.add(l, _dx.first),
  'addAll': (l) => _ndblFeats.addAll(l, _dx),
  'followedBy': (l) => _ndblFeats.followedBy(l, _dx),
  'fillRange': (l) => _ndblFeats.fillRange(l, 3, 5, _dx.first),
  'fillRange (all)': (l) => _ndblFeats.fillRange(l, 0, l.length, _dx.first),
  'fillRange (invalid)': (l) =>
      _ndblFeats.fillRange(l, -1, l.length, _dx.first),
  'setAll (start)': (l) => _ndblFeats.setAll(l, 0, _dx),
  'setAll (mid)': (l) => _ndblFeats.setAll(l, 3, _dx),
  'setAll (end)': (l) => _ndblFeats.setAll(l, l.length - 1, _dx),
  'setAll (invalid)': (l) => _ndblFeats.setAll(l, l.length, _dx),
  'insert (start)': (l) => _ndblFeats.insert(l, 0, _dx.first),
  'insert (mid)': (l) => _ndblFeats.insert(l, 3, _dx.first),
  'insert (end)': (l) => _ndblFeats.insert(l, l.length - 1, _dx.first),
  'insert (invalid)': (l) => _ndblFeats.insert(l, l.length, _dx.first),
  'insertAll (start)': (l) => _ndblFeats.insertAll(l, 0, _dx),
  'insertAll (mid)': (l) => _ndblFeats.insertAll(l, 3, _dx),
  'insertAll (end)': (l) => _ndblFeats.insertAll(l, l.length - 1, _dx),
  'insertAll (invalid)': (l) => _ndblFeats.insertAll(l, l.length, _dx),
  'remove': (l) => _ndblFeats.remove(l, 1.1),
  'removeAt': (l) => _ndblFeats.removeAt(l, 2),
  'removeLast': _ndblFeats.removeLast,
  'removeRange': (l) => _ndblFeats.removeRange(l, 3, 6),
  'removeWhere': (l) => _ndblFeats.removeWhere(l, _isGt3),
  'retainWhere': (l) => _ndblFeats.retainWhere(l, _isGt3),
  'setRange': (l) => _ndblFeats.setRange(l, 3, 6, _dx, null),
  'setRange (skip)': (l) => _ndblFeats.setRange(l, 3, 6, _dx, 1),
  'replaceRange': (l) => _ndblFeats.replaceRange(l, 3, 6, _dx),
  'clear': _ndblFeats.clear,
  'shuffle': (l) => _ndblFeats.shuffle(l, Random(_seed)),
  'toString': _ndblFeats.getString,
  'join': (l) => _ndblFeats.join(l, null),
  'join (dollar)': (l) => _ndblFeats.join(l, ' \$ '),
};

// ints
final _ix = [12, 13, 14, 15];

final _nintFeats = _Features<int?>();
final _nintTests = <String, _FeatureTest<int?>>{
  'isEmpty': _nintFeats.isEmpty,
  'isNotEmpty': _nintFeats.isNotEmpty,
  'read length': _nintFeats.getLength,
  'decrease length': (l) => _nintFeats.decreaseLength(l, 2),
  'increase length': (l) => _nintFeats.increaseLength(l, 2),
  'read single': _nintFeats.getSingle,
  'read first': _nintFeats.getFirst,
  'read last': _nintFeats.getLast,
  'read by index': (l) => _nintFeats.getAt(l, 2),
  'read by index (invalid)': (l) => _nintFeats.getAt(l, -1),
  'set first': (l) => _nintFeats.setFirst(l, _ix.first),
  'set last': (l) => _nintFeats.setLast(l, _ix.first),
  'set by index': (l) => _nintFeats.setAt(l, 2, _ix.first),
  'set by index (invalid)': (l) => _nintFeats.setAt(l, -1, _ix.first),
  'elementAt': (l) => _nintFeats.elementAt(l, 2),
  'elementAt (invalid)': (l) => _nintFeats.elementAt(l, -1),
  'getRange': (l) => _nintFeats.getRange(l, 3, 6),
  'contains': (l) => _nintFeats.contains(l, 2),
  'contains (miss)': (l) => _nintFeats.contains(l, -1),
  'find index': (l) => _nintFeats.indexOf(l, 2, null),
  'find index (skip)': (l) => _nintFeats.indexOf(l, 2, 3),
  'find index (miss)': (l) => _nintFeats.indexOf(l, -1, null),
  'last index': (l) => _nintFeats.lastIndexOf(l, 2, null),
  'last index (skip)': (l) => _nintFeats.lastIndexOf(l, 2, 3),
  'last index (miss)': (l) => _nintFeats.lastIndexOf(l, -1, null),
  'find where': (l) => _nintFeats.indexWhere(l, _isGt3, null),
  'find where (skip)': (l) => _nintFeats.indexWhere(l, _isGt3, 4),
  'find where (miss)': (l) => _nintFeats.indexWhere(l, _isNeg, null),
  'last where': (l) => _nintFeats.lastIndexWhere(l, _isGt3, null),
  'last where (skip)': (l) => _nintFeats.lastIndexWhere(l, _isGt3, 4),
  'last where (miss)': (l) => _nintFeats.lastIndexWhere(l, _isNeg, null),
  'cast': _nintFeats.cast<num?>,
  'toList': _nintFeats.toList,
  'subList (all from start)': (l) => _nintFeats.sublist(l, 0, null),
  'subList (all from mid)': (l) => _nintFeats.sublist(l, 3, null),
  'subList (all from end)': (l) => _nintFeats.sublist(l, l.length - 1, null),
  'subList (start to end)': (l) => _nintFeats.sublist(l, 0, 6),
  'subList (mid to end)': (l) => _nintFeats.sublist(l, 3, 6),
  'subList (end to end)': (l) => _nintFeats.sublist(l, l.length - 1, l.length),
  'subList (invalid range)': (l) => _nintFeats.sublist(l, 4, 3),
  'subList (invalid start)': (l) => _nintFeats.sublist(l, l.length, null),
  'subList (invalid end)': (l) => _nintFeats.sublist(l, 0, l.length + 1),
  'toSet': _nintFeats.toSet,
  'asMap': _nintFeats.asMap,
  'reversed': _nintFeats.reversed,
  'map': (l) => _nintFeats.map(l, _isGt3),
  'expand': (l) => _nintFeats.expand(l, (n) => [n, n == null ? null : n * n]),
  'fold': (l) => _nintFeats.fold(l, 0, (s, n) => s + (n ?? 0)),
  'reduce': (l) => _nintFeats.reduce(l, (s, n) => (s ?? 0) + (n ?? 0)),
  'any': (l) => _nintFeats.any(l, _isGt3),
  'any (miss)': (l) => _nintFeats.any(l, _isNeg),
  'every': (l) => _nintFeats.every(l, _isGt3),
  'every (full)': (l) => _nintFeats.every(l, _isNum),
  'skip': (l) => _nintFeats.skip(l, 3),
  'skip while': (l) => _nintFeats.skipWhile(l, _isInt),
  'skip while (miss)': (l) => _nintFeats.skipWhile(l, _isNeg),
  'take': (l) => _nintFeats.take(l, 3),
  'take while': (l) => _nintFeats.takeWhile(l, _isInt),
  'take while (miss)': (l) => _nintFeats.takeWhile(l, _isNeg),
  'where': (l) => _nintFeats.where(l, _isGt4),
  'where (miss)': (l) => _nintFeats.where(l, _isNeg),
  'where type': _nintFeats.whereType<Null>,
  'where type (miss)': _nintFeats.whereType<String>,
  'singleWhere': (l) => _nintFeats.singleWhere(l, (n) => n == 2, null),
  'singleWhere (match)': (l) => _nintFeats.singleWhere(l, (n) => n == 2, _nf),
  'singleWhere (many)': (l) => _nintFeats.singleWhere(l, _isGt3, null),
  'singleWhere (-1 on many)': (l) => _nintFeats.singleWhere(l, _isGt3, _nf),
  'firstWhere': (l) => _nintFeats.firstWhere(l, _isGt4, null),
  'firstWhere (match)': (l) => _nintFeats.firstWhere(l, _isGt4, _nf),
  'firstWhere (miss)': (l) => _nintFeats.firstWhere(l, _isNeg, null),
  'firstWhere (-1 on miss)': (l) => _nintFeats.firstWhere(l, _isNeg, _nf),
  'lastWhere': (l) => _nintFeats.lastWhere(l, _isGt4, null),
  'lastWhere (match)': (l) => _nintFeats.lastWhere(l, _isGt4, _nf),
  'lastWhere (miss)': (l) => _nintFeats.lastWhere(l, _isNeg, null),
  'lastWhere (-1 on miss)': (l) => _nintFeats.lastWhere(l, _isNeg, _nf),
  'forEach': (l) => _nintFeats.forEach(l, (_) {}),
  'concat': (l) => _nintFeats.concat(l, _ix),
  'concat (empty)': (l) => _nintFeats.concat(l, []),
  'add': (l) => _nintFeats.add(l, _ix.first),
  'addAll': (l) => _nintFeats.addAll(l, _ix),
  'followedBy': (l) => _nintFeats.followedBy(l, _ix),
  'fillRange': (l) => _nintFeats.fillRange(l, 3, 5, _ix.first),
  'fillRange (all)': (l) => _nintFeats.fillRange(l, 0, l.length, _ix.first),
  'fillRange (invalid)': (l) =>
      _nintFeats.fillRange(l, -1, l.length, _ix.first),
  'setAll (start)': (l) => _nintFeats.setAll(l, 0, _ix),
  'setAll (mid)': (l) => _nintFeats.setAll(l, 3, _ix),
  'setAll (end)': (l) => _nintFeats.setAll(l, l.length - 1, _ix),
  'setAll (invalid)': (l) => _nintFeats.setAll(l, l.length, _ix),
  'insert (start)': (l) => _nintFeats.insert(l, 0, _ix.first),
  'insert (mid)': (l) => _nintFeats.insert(l, 3, _ix.first),
  'insert (end)': (l) => _nintFeats.insert(l, l.length - 1, _ix.first),
  'insert (invalid)': (l) => _nintFeats.insert(l, l.length, _ix.first),
  'insertAll (start)': (l) => _nintFeats.insertAll(l, 0, _ix),
  'insertAll (mid)': (l) => _nintFeats.insertAll(l, 3, _ix),
  'insertAll (end)': (l) => _nintFeats.insertAll(l, l.length - 1, _ix),
  'insertAll (invalid)': (l) => _nintFeats.insertAll(l, l.length, _ix),
  'remove': (l) => _nintFeats.remove(l, 2),
  'removeAt': (l) => _nintFeats.removeAt(l, 2),
  'removeLast': _nintFeats.removeLast,
  'removeRange': (l) => _nintFeats.removeRange(l, 3, 6),
  'removeWhere': (l) => _nintFeats.removeWhere(l, _isGt3),
  'retainWhere': (l) => _nintFeats.retainWhere(l, _isGt3),
  'setRange': (l) => _nintFeats.setRange(l, 3, 6, _ix, null),
  'setRange (skip)': (l) => _nintFeats.setRange(l, 3, 6, _ix, 1),
  'replaceRange': (l) => _nintFeats.replaceRange(l, 3, 6, _ix),
  'clear': _nintFeats.clear,
  'shuffle': (l) => _nintFeats.shuffle(l, Random(_seed)),
  'toString': _nintFeats.getString,
  'join': (l) => _nintFeats.join(l, null),
  'join (dollar)': (l) => _nintFeats.join(l, ' \$ '),
};

// helpers
final _seed = DateTime.now().millisecondsSinceEpoch ~/ 1000;

final _int = NumConverter.instance.value<int>();
final _nint = Converter.allowNull(_int);
final _dbl = NumConverter.instance.value<double>();
final _ndbl = Converter.allowNull(_dbl);

bool _isNum(num? n) => n is num;
bool _isGt3(num? n) => (n != null) && (_dbl(n) > 3);
bool _isGt4(num? n) => (n != null) && (_dbl(n) > 4);
bool _isInt(num? n) => _isNum(n) && (_dbl(n).toInt().toDouble() == _dbl(n));

bool _isNeg(num? n) => (n != null) && (_dbl(n) < 0);

T _nf<T>() => -1 as T;

typedef _Action<T> = void Function(T);
typedef _DataContext<T> = ({LazyInPlaceList<T> lazy, List<T> ref});
typedef _Default<T> = T Function();
typedef _FeatureTest<T> = dynamic Function(List<T>);
typedef _Mapper<T, U> = U Function(T);
typedef _Reducer<U, V, X> = X Function(U, V);

class _Features<T> {
  List<T> add(List<T> l, T v) => l..add(v);

  List<T> addAll(List<T> l, Iterable<T> x) => l..addAll(x);

  bool any(List<T> l, _Mapper<T, bool> t) => l.any(t);

  Map<int, T> asMap(List<T> l) => l.asMap();

  List<U> cast<U>(List<T> l) => l.cast<U>();

  List<T> clear(List<T> l) => l..clear();

  List<T> concat(List<T> l, List<T> x) => l + x;

  bool contains(List<T> l, dynamic v) => l.contains(v);

  int decreaseLength(List<T> l, int c) {
    l.length -= c;
    return l.length;
  }

  T elementAt(List<T> l, int i) => l.elementAt(i);

  bool every(List<T> l, _Mapper<T, bool> t) => l.every(t);

  Iterable<U> expand<U>(List<T> l, _Mapper<T, Iterable<U>> e) => l.expand(e);

  void fillRange(List<T> l, int s, int e, T? v) => l.fillRange(s, e, v);

  T firstWhere(List<T> l, _Mapper<T, bool> t, _Default<T>? d) =>
      l.firstWhere(t, orElse: d);

  U fold<U>(List<T> l, U v, _Reducer<U, T, U> f) => l.fold(v, f);

  Iterable<T> followedBy(List<T> l, Iterable<T> x) => l.followedBy(x);

  int forEach(List<T> l, _Action<T> a) {
    var n = 0;
    void $a(T i) {
      a(i);
      n++;
    }

    l.forEach($a);
    return n;
  }

  T getAt(List<T> l, int i) => l[i];

  T getFirst(List<T> l) => l.first;

  T getLast(List<T> l) => l.last;

  int getLength(List<T> l) => l.length;

  Iterable<T> getRange(List<T> l, int s, int e) => l.getRange(s, e);

  T getSingle(List<T> l) => l.single;

  String getString(List<T> l) => l.toString();

  int increaseLength(List<T> l, int c) {
    l.length += c;
    return l.length;
  }

  int indexOf(List<T> l, T e, int? s) => l.indexOf(e, s ?? 0);

  int indexWhere(List<T> l, _Mapper<T, bool> t, int? s) =>
      l.indexWhere(t, s ?? 0);

  List<T> insert(List<T> l, int i, T v) => l..insert(i, v);

  List<T> insertAll(List<T> l, int i, Iterable<T> x) => l..insertAll(i, x);

  bool isEmpty(List<T> l) => l.isEmpty;

  bool isNotEmpty(List<T> l) => l.isNotEmpty;

  String join(List<T> l, String? s) => l.join(s ?? '');

  int lastIndexOf(List<T> l, T v, int? s) => l.lastIndexOf(v, s);

  int lastIndexWhere(List<T> l, _Mapper<T, bool> t, int? s) =>
      l.lastIndexWhere(t, s);

  T lastWhere(List<T> l, _Mapper<T, bool> t, _Default<T>? d) =>
      l.lastWhere(t, orElse: d);

  Iterable<U> map<U>(List<T> l, _Mapper<T, U> e) => l.map(e);

  T reduce(List<T> l, _Reducer<T, T, T> c) => l.reduce(c);

  bool remove(List<T> l, dynamic v) => l.remove(v);

  T removeAt(List<T> l, int i) => l.removeAt(i);

  T removeLast(List<T> l) => l.removeLast();

  List<T> removeRange(List<T> l, int s, int e) => l..removeRange(s, e);

  List<T> removeWhere(List<T> l, _Mapper<T, bool> t) => l..removeWhere(t);

  List<T> replaceRange(List<T> l, int s, int e, Iterable<T> r) =>
      l..replaceRange(s, e, r);

  List<T> retainWhere(List<T> l, _Mapper<T, bool> t) => l..retainWhere(t);

  Iterable<T> reversed(List<T> l) => l.reversed;

  List<T> setAll(List<T> l, int i, Iterable<T> x) => l..setAll(i, x);

  T setAt(List<T> l, int i, T v) {
    l[i] = v;
    return l[i];
  }

  T setFirst(List<T> l, T v) {
    l.first = v;
    return l.first;
  }

  T setLast(List<T> l, T v) {
    l.last = v;
    return l.last;
  }

  List<T> setRange(List<T> l, int s, int e, Iterable<T> x, int? c) =>
      l..setRange(s, e, x, c ?? 0);

  List<T> shuffle(List<T> l, Random? random) => l..shuffle(random);

  T singleWhere(List<T> l, _Mapper<T, bool> t, _Default<T>? d) =>
      l.singleWhere(t, orElse: d);

  Iterable<T> skip(List<T> l, int c) => l.skip(c);

  Iterable<T> skipWhile(List<T> l, _Mapper<T, bool> t) => l.skipWhile(t);

  List<T> sort(List<T> l, _Reducer<T, T, int>? c) => l..sort(c);

  List<T> sublist(List<T> l, int s, int? e) => l.sublist(s, e);

  Iterable<T> take(List<T> l, int c) => l.take(c);

  Iterable<T> takeWhile(List<T> l, _Mapper<T, bool> t) => l.takeWhile(t);

  List<T> toList(List<T> l) => l.toList();

  Set<T> toSet(List<T> l) => l.toSet();

  Iterable<T> where(List<T> l, _Mapper<T, bool> t) => l.where(t);

  Iterable<U> whereType<U>(List<T> l) => l.whereType<U>();
}

extension _FeatureTestExt<T> on MapEntry<String, _FeatureTest<T>> {
  void check(TestContext tc, _DataContext<T> data) {
    tc.test('- $key', () {
      expect(data.lazy, data.ref, reason: '1');
      checkOutcome(key, data.lazy, data.ref, value, tc.runnerPlatform);
      expect(data.lazy, data.ref, reason: '2');
    });
  }
}
