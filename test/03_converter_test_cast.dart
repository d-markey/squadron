// ignore_for_file: file_names

part of '03_converter_test.dart';

// ignore: non_constant_identifier_names
void testCastConverter(TestContext tc) {
  tc.group('- CastConverter', () {
    final converter = CastConverter.instance;

    tc.group('- Integers', () {
      final $toInt = converter.value<int>();
      final $toNullableInt = Converter.allowNull($toInt);

      void $platformSensitive(dynamic value) {
        try {
          final res = $toInt(value);
          expect(res, value);
          _unexpectedSuccessIfNonJs('Operation succeeded', res);
        } catch (ex) {
          _unexpectedFailureIfJs('Operation failed', ex);
          if (!_isTypeError(ex)) rethrow;
        }

        try {
          final res = $toNullableInt(value);
          expect(res, value);
          _unexpectedSuccessIfNonJs('Operation succeeded', res);
        } catch (ex) {
          _unexpectedFailureIfJs('Operation failed', ex);
          if (!_isTypeError(ex)) rethrow;
        }
      }

      void $fails(dynamic value) {
        try {
          final res = $toInt(value);
          unexpectedSuccess('Operation succeeded', res);
        } catch (ex) {
          if (!_isTypeError(ex)) rethrow;
        }

        if (value == null) {
          expect($toNullableInt(value), isNull);
        } else {
          try {
            final res = $toNullableInt(value);
            unexpectedSuccess('Operation succeeded', res);
          } catch (ex) {
            if (!_isTypeError(ex)) rethrow;
          }
        }
      }

      void $succeeds(dynamic value) {
        final res = $toInt(value);
        expect(res, value);
        final nres = $toNullableInt(value);
        expect(nres, value);
      }

      tc.test('- Converters are identities', () {
        expect(Converter.isIdentity($toInt), isTrue);
        expect(Converter.isIdentity($toNullableInt), isTrue);
      });

      tc.test('- int', () {
        $succeeds(5);
      });

      tc.test('- double', () async {
        $platformSensitive(5.toDouble());
        $platformSensitive(-0.0);
        $platformSensitive(double.infinity);
        $platformSensitive(double.negativeInfinity);
        $fails(5.5);
        $fails(double.nan);
      });

      tc.test('- null', () async {
        $fails(null);
      });

      tc.test('- bool', () async {
        $fails(true);
        $fails(false);
      });

      tc.test('- String', () async {
        $fails('1');
        $fails('');
      });

      tc.test('- Object', () async {
        $fails(Object());
      });
    });

    tc.group('- Doubles', () {
      final $toDbl = converter.value<double>();
      final $toNullableDbl = Converter.allowNull($toDbl);

      void $platformSensitive(dynamic value) {
        try {
          final res = $toDbl(value);
          expect(res, value);
          _unexpectedSuccessIfNonJs('Operation succeeded', res);
        } catch (ex) {
          _unexpectedFailureIfJs('Operation failed', ex);
          if (!_isTypeError(ex)) rethrow;
        }

        try {
          final res = $toNullableDbl(value);
          expect(res, value);
          _unexpectedSuccessIfNonJs('Operation succeeded', res);
        } catch (ex) {
          _unexpectedFailureIfJs('Operation failed', ex);
          if (!_isTypeError(ex)) rethrow;
        }
      }

      void $fails(dynamic value) {
        try {
          final res = $toDbl(value);
          unexpectedSuccess('Operation succeeded', res);
        } catch (ex) {
          if (!_isTypeError(ex)) rethrow;
        }

        if (value == null) {
          expect($toNullableDbl(value), isNull);
        } else {
          try {
            final res = $toNullableDbl(value);
            unexpectedSuccess('Operation succeeded', res);
          } catch (ex) {
            if (!_isTypeError(ex)) rethrow;
          }
        }
      }

      void $succeeds(dynamic value) {
        final res = $toDbl(value);
        expect(res, value);
        final nres = $toNullableDbl(value);
        expect(nres, value);
      }

      tc.test('- Converters are identities', () {
        expect(Converter.isIdentity($toDbl), isTrue);
        expect(Converter.isIdentity($toNullableDbl), isTrue);
      });

      tc.test('- int', () {
        $platformSensitive(5);
      });

      tc.test('- double', () {
        $succeeds(5.5);
        $succeeds(-0.0);
        $succeeds(double.infinity);
        $succeeds(double.negativeInfinity);
        expect($toDbl(double.nan), isNaN);
        expect($toNullableDbl(double.nan), isNaN);
      });

      tc.test('- null', () async {
        $fails(null);
      });

      tc.test('- bool', () async {
        $fails(true);
        $fails(false);
      });

      tc.test('- String', () async {
        $fails('1');
        $fails('1.1');
        $fails('');
      });

      tc.test('- Object', () async {
        $fails(Object());
      });
    });

    tc.group('- Lists', () {
      tc.test('- Integers (cast conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfInts);

        await expectLater(() => data as List<int>, _throwsTypeError);
        final res = converter.list<int>()(data);
        expect(res, isA<List<int>>());
        expect(res, data);
        expect(res, _listOfInts);
      });

      tc.test('- Integers (custom conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfInts);

        await expectLater(() => data as List<int>, _throwsTypeError);
        final res = converter.list<int>(_asInt)(data);
        expect(res, isA<List<int>>());
        expect(res, _listOfInts);
      });

      tc.test('- Nullable integers', () async {
        final data = <dynamic>[];
        data.addAll(_listOfNullableInts);

        await expectLater(() => data as List<int?>, _throwsTypeError);
        final res = converter.nlist<int>(converter.value<int>())(data);
        expect(res, isA<List<int?>>());
        expect(res, _listOfNullableInts);
      });

      tc.test('- Integers + integral double (cast conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfIntsWithIntegralDouble);

        await expectLater(() => data as List<int>, _throwsTypeError);
        final res = converter.list<int>()(data);
        expect(res, isA<List<int>>());
        try {
          expect(res, _listOfIntsWithIntegralDouble);
          _unexpectedSuccessIfNonJs('integral double to int', res);
        } on TypeError catch (ex) {
          _unexpectedFailureIfJs('integral double to int', ex);
        }
      });

      tc.test('- Integers + integral double (custom conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfIntsWithIntegralDouble);

        await expectLater(() => data as List<int>, _throwsTypeError);
        try {
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
        final res = converter.list<double>()(data);
        expect(res, isA<List<double>>());
        expect(res, _listOfDoubles);
      });

      tc.test('- Nullable doubles', () async {
        final data = <dynamic>[];
        data.addAll(_listOfNullableDoubles);

        await expectLater(() => data as List<double?>, _throwsTypeError);
        final res = converter.nlist<double>(converter.value<double>())(data);
        expect(res, isA<List<double?>>());
        expect(res, _listOfNullableDoubles);
      });

      tc.test('- Doubles + integer', () async {
        final data = <dynamic>[];
        data.addAll(_listOfDoublesWithInt);

        await expectLater(() => data as List<double>, _throwsTypeError);
        final res = converter.list<double>()(data);
        expect(res, isA<List<double>>());
        try {
          expect(res, _listOfDoublesWithInt);
          _unexpectedSuccessIfNonJs('int to double', res);
        } on TypeError catch (ex) {
          _unexpectedFailureIfJs('int to double', ex);
        }
      });
    });

    tc.group('- Sets', () {
      tc.test('- Integers (cast conversion)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfInts);

        await expectLater(() => data as Set<int>, _throwsTypeError);
        final res = converter.set<int>()(data);
        expect(res, isA<Set<int>>());
        expect(res, _listOfInts.toSet());
      });

      tc.test('- Integers (custom conversion)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfInts);

        await expectLater(() => data as Set<int>, _throwsTypeError);
        final res = converter.set<int>()(data);
        expect(res, isA<Set<int>>());
        expect(res, _listOfInts.toSet());
      });

      tc.test('- Nullable integers', () async {
        final data = <dynamic>{};
        data.addAll(_listOfNullableInts);

        await expectLater(() => data as Set<int?>, _throwsTypeError);
        final res = converter.nset<int>(converter.value<int>())(data);
        expect(res, isA<Set<int?>>());
        expect(res, _listOfNullableInts.toSet());
      });

      tc.test('- Integers + integral double (cast conversion)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfIntsWithIntegralDouble);

        await expectLater(() => data as Set<int>, _throwsTypeError);
        try {
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
        final res = converter.set<double>()(data);
        expect(res, isA<Set<double>>());
        expect(res, _listOfDoubles.toSet());
      });

      tc.test('- Nullable doubles', () async {
        final data = <dynamic>{};
        data.addAll(_listOfNullableDoubles);

        await expectLater(() => data as Set<double?>, _throwsTypeError);
        final res = converter.nset<double>(converter.value<double>())(data);
        expect(res, isA<Set<double?>>());
        expect(res, _listOfNullableDoubles.toSet());
      });

      tc.test('- Doubles + integer', () async {
        final data = <dynamic>{};
        data.addAll(_listOfDoublesWithInt);

        await expectLater(() => data as Set<double>, _throwsTypeError);
        try {
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
        final res = converter.map<String, int>()(data);
        expect(res, isA<Map<String, int>>());
        expect(res, _mapOfInts);
      });

      tc.test('- String / integer (custom conversion)', () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfInts);

        await expectLater(() => data as Map<String, int>, _throwsTypeError);
        final res = converter.map<String, int>(vcast: _asInt)(data);
        expect(res, isA<Map<String, int>>());
        expect(res, _mapOfInts);
      });

      tc.test('- String / nullable integer', () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfNullableInts);

        await expectLater(() => data as Map<String, int>, _throwsTypeError);
        final res =
            converter.nmap<String, int>(vcast: converter.value<int>())(data);
        expect(res, isA<Map<String, int?>>());
        expect(res, _mapOfNullableInts);
      });

      tc.test('- String / integers + integral double (cast conversion)',
          () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfIntsWithIntegralDouble);

        await expectLater(() => data as Map<String, int>, _throwsTypeError);
        final res = converter.map<String, int>()(data);
        expect(res, isA<Map<String, int>>());
        try {
          expect(res, _mapOfIntsWithIntegralDouble);
          _unexpectedSuccessIfNonJs('integral double to int', res);
        } on TypeError catch (ex) {
          _unexpectedFailureIfJs('integral double to int', ex);
        }
      });

      tc.test('- String / integers + integral double (custom conversion)',
          () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfIntsWithIntegralDouble);

        await expectLater(() => data as Map<String, int>, _throwsTypeError);
        try {
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
        final a = <num>[1, 2, 3, 4, 5], b = <num>[1, 2, 3, 4, 5];
        expect(a, isNotA<List<int>>());
        expect(b, isNotA<List<int>>());
        final ca = converter.list<int>()(a);
        final cb = converter.list<int>()(b);
        expect(ca, isA<List<int>>());
        expect(cb, isA<List<int>>());
        expect(ca, cb);
        expect(identical(ca, cb), isFalse);
      });

      tc.test('Same instance', () {
        final a = <num>[1, 2, 3, 4, 5], b = a;
        expect(a, isNotA<List<int>>());
        expect(b, isNotA<List<int>>());
        final ca = converter.list<int>()(a);
        final cb = converter.list<int>()(b);
        expect(ca, isA<List<int>>());
        expect(cb, isA<List<int>>());
        expect(ca, cb);
        // CastConverter is not context aware
        expect(identical(ca, cb), isFalse);
      });
    });
  });
}
