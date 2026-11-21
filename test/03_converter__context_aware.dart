// ignore_for_file: file_names

part of '03_converter_suite.dart';

// ignore: non_constant_identifier_names
void testContextAwareConverter(TestContext tc) {
  tc.group('- ContextAwareConverter', () {
    final numConverter = NumConverter.instance;

    tc.group('- Lists', () {
      tc.test('- Integers (cast conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfInts);
        await expectLater(() => data as List<int>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.list<int>()(data);

        expect(res, _listOfInts);
        expect(identical(res, _listOfInts), isFalse);

        final res2 = converter.list<int>()(data);

        expect(res2, _listOfInts);
        expect(identical(res2, _listOfInts), isFalse);
        expect(identical(res2, res), isTrue);

        converter.clearContext();

        final res3 = converter.list<int>()(data);

        expect(res3, _listOfInts);
        expect(identical(res3, _listOfInts), isFalse);
        expect(identical(res3, res), isFalse);
      });

      tc.test('- Integers (custom conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfInts);
        await expectLater(() => data as List<int>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.list<int>(_asInt)(data);

        expect(res, _listOfInts);
        expect(identical(res, _listOfInts), isFalse);
      });

      tc.test('- Nullable integers', () async {
        final data = <dynamic>[];
        data.addAll(_listOfNullableInts);
        await expectLater(() => data as List<int?>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.nlist<int>(converter.value<int>())(data);

        expect(res, isA<List<int?>>());
        expect(res, _listOfNullableInts);
      });

      tc.test('- Integers + integral double (cast conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfIntsWithIntegralDouble);
        await expectLater(() => data as List<int>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.list<int>()(data);

        expect(res, isA<List<int>>());
        expect(res, _listOfIntsWithIntegralDouble);
      });

      tc.test('- Integers + integral double (custom conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfIntsWithIntegralDouble);
        await expectLater(() => data as List<int>, _throwsTypeError);

        try {
          final converter = ContextAwareConverter(numConverter);
          final res = converter.list<int>(_asInt)(data);
          expect(res, isA<List<int>>());
          expect(res, _listOfIntsWithIntegralDouble);
          _unexpectedSuccessIfNonJs('integral double to int', res);
        } on TypeError catch (ex) {
          _unexpectedFailureIfJs('integral double to int', ex);
        }
      });

      tc.test('- Doubles', () async {
        final data = <dynamic>[];
        data.addAll(_listOfDoubles);
        await expectLater(() => data as List<double>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.list<double>()(data);

        expect(res, isA<List<double>>());
        expect(res, _listOfDoubles);
      });

      tc.test('- Nullable doubles', () async {
        final data = <dynamic>[];
        data.addAll(_listOfNullableDoubles);
        await expectLater(() => data as List<double?>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.nlist<double>(converter.value<double>())(data);

        expect(res, isA<List<double?>>());
        expect(res, _listOfNullableDoubles);
      });

      tc.test('- Doubles + integer', () async {
        final data = <dynamic>[];
        data.addAll(_listOfDoublesWithInt);
        await expectLater(() => data as List<double>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.list<double>()(data);

        expect(res, isA<List<double>>());
        expect(res, _listOfDoublesWithInt);
      });
    });

    tc.group('- Sets', () {
      tc.test('- Integers (cast conversion)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfInts);
        await expectLater(() => data as Set<int>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.set<int>()(data);

        expect(res, isA<Set<int>>());
        expect(res, _listOfInts.toSet());
      });

      tc.test('- Integers (custom conversion)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfInts);
        await expectLater(() => data as Set<int>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.set<int>()(data);

        expect(res, isA<Set<int>>());
        expect(res, _listOfInts.toSet());
      });

      tc.test('- Nullable integers', () async {
        final data = <dynamic>{};
        data.addAll(_listOfNullableInts);
        await expectLater(() => data as Set<int?>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.nset<int>(converter.value<int>())(data);

        expect(res, isA<Set<int?>>());
        expect(res, _listOfNullableInts.toSet());
      });

      tc.test('- Integers + integral double (cast conversion)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfIntsWithIntegralDouble);
        await expectLater(() => data as Set<int>, _throwsTypeError);

        try {
          final converter = ContextAwareConverter(numConverter);
          final res = converter.set<int>()(data);
          expect(res, isA<Set<int>>());
          expect(res, _listOfIntsWithIntegralDouble.toSet());
          _unexpectedSuccessIfNonJs('integral double to int', res);
        } catch (ex) {
          _unexpectedFailureIfJs('integral double to int', ex);
        }
      });

      tc.test('- Integers + integral double (custom conversion)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfIntsWithIntegralDouble);
        await expectLater(() => data as Set<int>, _throwsTypeError);

        try {
          final converter = ContextAwareConverter(numConverter);
          final res = converter.set<int>(_asInt)(data);
          expect(res, isA<Set<int>>());
          expect(res, _listOfIntsWithIntegralDouble.toSet());
          _unexpectedSuccessIfNonJs('integral double to int', res);
        } on TypeError catch (ex) {
          _unexpectedFailureIfJs('integral double to int', ex);
        }
      });

      tc.test('- Doubles', () async {
        final data = <dynamic>{};
        data.addAll(_listOfDoubles);
        await expectLater(() => data as Set<double>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.set<double>()(data);

        expect(res, isA<Set<double>>());
        expect(res, _listOfDoubles.toSet());
      });

      tc.test('- Nullable doubles', () async {
        final data = <dynamic>{};
        data.addAll(_listOfNullableDoubles);
        await expectLater(() => data as Set<double?>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.nset<double>()(data);

        expect(res, isA<Set<double?>>());
        expect(res, _listOfNullableDoubles.toSet());
      });

      tc.test('- Doubles + integer', () async {
        final data = <dynamic>{};
        data.addAll(_listOfDoublesWithInt);

        await expectLater(() => data as Set<double>, _throwsTypeError);
        try {
          final converter = ContextAwareConverter(numConverter);
          final res = converter.set<double>()(data);
          expect(res, isA<Set<double>>());
          expect(res, _listOfDoublesWithInt.toSet());
          _unexpectedSuccessIfNonJs('integral double to int', res);
        } catch (ex) {
          _unexpectedFailureIfJs('integral double to int', ex);
        }
      });
    });

    tc.group('- Maps', () {
      tc.test('- String / integer (cast conversion)', () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfInts);
        await expectLater(() => data as Map<String, int>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.map<String, int>()(data);

        expect(res, isA<Map<String, int>>());
        expect(res, _mapOfInts);
      });

      tc.test('- String / integer (custom conversion)', () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfInts);
        await expectLater(() => data as Map<String, int>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.map<String, int>(vcast: _asInt)(data);

        expect(res, isA<Map<String, int>>());
        expect(res, _mapOfInts);
      });

      tc.test('- String / nullable integer', () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfNullableInts);
        await expectLater(() => data as Map<String, int>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.nmap<String, int>()(data);

        expect(res, isA<Map<String, int?>>());
        expect(res, _mapOfNullableInts);
      });

      tc.test('- String / integers + integral double (cast conversion)',
          () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfIntsWithIntegralDouble);
        await expectLater(() => data as Map<String, int>, _throwsTypeError);

        final converter = ContextAwareConverter(numConverter);
        final res = converter.map<String, int>()(data);

        expect(res, isA<Map<String, int>>());
        expect(res, _mapOfIntsWithIntegralDouble);
      });

      tc.test('- String / integers + integral double (custom conversion)',
          () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfIntsWithIntegralDouble);
        await expectLater(() => data as Map<String, int>, _throwsTypeError);

        try {
          final converter = ContextAwareConverter(numConverter);
          final res = converter.map<String, int>(vcast: _asInt)(data);
          expect(res, isA<Map<String, int>>());
          expect(res, _mapOfIntsWithIntegralDouble);
          _unexpectedSuccessIfNonJs('integral double to int', res);
        } on TypeError catch (ex) {
          _unexpectedFailureIfJs('integral double to int', ex);
        }
      });
    });

    tc.group('Instances', () {
      tc.test('Different instances', () {
        final a = <num>[1, 2, 3.0, 4, 5], b = <num>[1, 2, 3.0, 4, 5];
        expect(a, isNotA<List<int>>());
        expect(b, isNotA<List<int>>());
        final converter = ContextAwareConverter(numConverter);
        final ca = converter.list<int>()(a);
        final cb = converter.list<int>()(b);
        expect(ca, isA<List<int>>());
        expect(cb, isA<List<int>>());
        expect(ca, cb);
        expect(identical(ca, cb), isFalse);
      });

      tc.test('Same instance', () {
        final a = <num>[1, 2, 3.0, 4, 5], b = a;
        expect(a, isNotA<List<int>>());
        expect(b, isNotA<List<int>>());
        final converter = ContextAwareConverter(numConverter);
        final ca = converter.list<int>()(a);
        final cb = converter.list<int>()(b);
        expect(ca, isA<List<int>>());
        expect(cb, isA<List<int>>());
        expect(ca, cb);
        expect(identical(ca, cb), isTrue);
      });
    });
  });
}
