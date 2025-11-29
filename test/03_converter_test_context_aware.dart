// ignore_for_file: file_names

part of '03_converter_test.dart';

// ignore: non_constant_identifier_names
void testContextAwareConverter(TestContext tc) {
  tc.group('- ContextAwareConverter', () {
    tc.group('- Integers', () {
      final $toInt = NumConverter.instance.value<int>();
      final $toNullableInt = Converter.allowNull($toInt);

      tc.test('- Converters are not identities', () {
        expect(Converter.isIdentity($toInt), isFalse);
        expect(Converter.isIdentity($toNullableInt), isFalse);
      });

      tc.test('- int', () {
        expect($toInt(5), 5);
        expect($toNullableInt(5), 5);
      });

      tc.test('- double', () async {
        expect($toInt(5.toDouble()), 5);
        expect($toNullableInt(5.toDouble()), 5);

        await expectLater(() => $toInt(5.5), _throwsTypeError);
        await expectLater(() => $toNullableInt(5.5), _throwsTypeError);

        await expectLater(() => $toInt(double.infinity), _throwsTypeError);
        await expectLater(
            () => $toNullableInt(double.infinity), _throwsTypeError);

        await expectLater(
            () => $toInt(double.negativeInfinity), _throwsTypeError);
        await expectLater(
            () => $toNullableInt(double.negativeInfinity), _throwsTypeError);

        await expectLater(() => $toInt(double.nan), _throwsTypeError);
        await expectLater(() => $toNullableInt(double.nan), _throwsTypeError);

        expect($toInt(-0.0), 0);
        expect($toNullableInt(-0.0), 0);
      });

      tc.test('- null', () async {
        await expectLater(() => $toInt(null), _throwsTypeError);
        expect($toNullableInt(null), isNull);
      });

      tc.test('- bool', () async {
        await expectLater(() => $toInt(true), _throwsTypeError);
        await expectLater(() => $toNullableInt(true), _throwsTypeError);
      });

      tc.test('- String', () async {
        await expectLater(() => $toInt('1'), _throwsTypeError);
        await expectLater(() => $toNullableInt('1'), _throwsTypeError);
        await expectLater(() => $toNullableInt('1.1'), _throwsTypeError);
        await expectLater(() => $toNullableInt('garbage'), _throwsTypeError);
      });

      tc.test('- Object', () async {
        await expectLater(() => $toInt(Object()), _throwsTypeError);
        await expectLater(() => $toNullableInt(Object()), _throwsTypeError);
      });
    });

    tc.group('- Doubles', () {
      final $toDbl = NumConverter.instance.value<double>();
      final $toNullableDbl = Converter.allowNull($toDbl);

      tc.test('- Converters are not identities', () {
        expect(Converter.isIdentity($toDbl), isFalse);
        expect(Converter.isIdentity($toNullableDbl), isFalse);
      });

      tc.test('- int', () {
        expect($toDbl(5.toInt()), 5);
        expect($toNullableDbl(5.toInt()), 5);
      });

      tc.test('- double', () {
        expect($toDbl(5.5), 5.5);
        expect($toNullableDbl(5.5), 5.5);

        expect($toDbl(-0.0), -0.0);
        expect($toNullableDbl(-0.0), -0.0);

        expect($toDbl(double.infinity), _isInfinite);
        expect($toNullableDbl(double.infinity), _isInfinite);

        expect($toDbl(double.negativeInfinity), _isInfinite);
        expect($toNullableDbl(double.negativeInfinity), _isInfinite);

        expect($toDbl(double.nan), isNaN);
        expect($toNullableDbl(double.nan), isNaN);
      });

      tc.test('- null', () async {
        await expectLater(() => $toDbl(null), _throwsTypeError);
        expect($toNullableDbl(null), isNull);
      });

      tc.test('- bool', () async {
        await expectLater(() => $toDbl(true), _throwsTypeError);
        await expectLater(() => $toNullableDbl(true), _throwsTypeError);
      });

      tc.test('- String', () async {
        await expectLater(() => $toDbl('1'), _throwsTypeError);
        await expectLater(() => $toNullableDbl('1'), _throwsTypeError);
      });

      tc.test('- Object', () async {
        await expectLater(() => $toDbl(Object()), _throwsTypeError);
        await expectLater(() => $toNullableDbl(Object()), _throwsTypeError);
      });
    });

    tc.group('- Lists', () {
      tc.test('- Integers (cast conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfInts);
        await expectLater(() => data as List<int>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.list<int>()(data);

        expect(res, isA<List<int>>());
        expect(res, _listOfInts);
      });

      tc.test('- Integers (custom conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfInts);
        await expectLater(() => data as List<int>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.list<int>(_asInt)(data);

        expect(res, isA<List<int>>());
        expect(res, _listOfInts);
      });

      tc.test('- Nullable integers', () async {
        final data = <dynamic>[];
        data.addAll(_listOfNullableInts);
        await expectLater(() => data as List<int?>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.nlist<int>(converter.value<int>())(data);

        expect(res, isA<List<int?>>());
        expect(res, _listOfNullableInts);
      });

      tc.test('- Integers + integral double (cast conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfIntsWithIntegralDouble);
        await expectLater(() => data as List<int>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.list<int>()(data);

        expect(res, isA<List<int>>());
        expect(res, _listOfIntsWithIntegralDouble);
      });

      tc.test('- Integers + integral double (custom conversion)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfIntsWithIntegralDouble);
        await expectLater(() => data as List<int>, _throwsTypeError);

        try {
          final converter = ContextAwareConverter(NumConverter.instance);
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

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.list<double>()(data);

        expect(res, isA<List<double>>());
        expect(res, _listOfDoubles);
      });

      tc.test('- Nullable doubles', () async {
        final data = <dynamic>[];
        data.addAll(_listOfNullableDoubles);
        await expectLater(() => data as List<double?>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.nlist<double>(converter.value<double>())(data);

        expect(res, isA<List<double?>>());
        expect(res, _listOfNullableDoubles);
      });

      tc.test('- Doubles + integer', () async {
        final data = <dynamic>[];
        data.addAll(_listOfDoublesWithInt);
        await expectLater(() => data as List<double>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
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

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.set<int>()(data);

        expect(res, isA<Set<int>>());
        expect(res, _listOfInts.toSet());
      });

      tc.test('- Integers (custom conversion)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfInts);
        await expectLater(() => data as Set<int>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.set<int>()(data);

        expect(res, isA<Set<int>>());
        expect(res, _listOfInts.toSet());
      });

      tc.test('- Nullable integers', () async {
        final data = <dynamic>{};
        data.addAll(_listOfNullableInts);
        await expectLater(() => data as Set<int?>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.nset<int>(converter.value<int>())(data);

        expect(res, isA<Set<int?>>());
        expect(res, _listOfNullableInts.toSet());
      });

      tc.test('- Integers + integral double (cast conversion)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfIntsWithIntegralDouble);
        await expectLater(() => data as Set<int>, _throwsTypeError);

        try {
          final converter = ContextAwareConverter(NumConverter.instance);
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
          final converter = ContextAwareConverter(NumConverter.instance);
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

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.set<double>()(data);

        expect(res, isA<Set<double>>());
        expect(res, _listOfDoubles.toSet());
      });

      tc.test('- Nullable doubles', () async {
        final data = <dynamic>{};
        data.addAll(_listOfNullableDoubles);
        await expectLater(() => data as Set<double?>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.nset<double>()(data);

        expect(res, isA<Set<double?>>());
        expect(res, _listOfNullableDoubles.toSet());
      });

      tc.test('- Doubles + integer', () async {
        final data = <dynamic>{};
        data.addAll(_listOfDoublesWithInt);

        await expectLater(() => data as Set<double>, _throwsTypeError);
        try {
          final converter = ContextAwareConverter(NumConverter.instance);
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

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.map<String, int>()(data);

        expect(res, isA<Map<String, int>>());
        expect(res, _mapOfInts);
      });

      tc.test('- String / integer (custom conversion)', () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfInts);
        await expectLater(() => data as Map<String, int>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.map<String, int>(vcast: _asInt)(data);

        expect(res, isA<Map<String, int>>());
        expect(res, _mapOfInts);
      });

      tc.test('- String / nullable integer', () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfNullableInts);
        await expectLater(() => data as Map<String, int>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
        final res = converter.nmap<String, int>()(data);

        expect(res, isA<Map<String, int?>>());
        expect(res, _mapOfNullableInts);
      });

      tc.test('- String / integers + integral double (cast conversion)',
          () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfIntsWithIntegralDouble);
        await expectLater(() => data as Map<String, int>, _throwsTypeError);

        final converter = ContextAwareConverter(NumConverter.instance);
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
          final converter = ContextAwareConverter(NumConverter.instance);
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
        final converter = ContextAwareConverter(NumConverter.instance);
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
        final converter = ContextAwareConverter(NumConverter.instance);
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
