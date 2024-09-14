// ignore_for_file: file_names

part of '03_converter_test.dart';

void testInPlaceCastConverter(TestContext tc) {
  tc.group('- InPlaceConverter + CastConverter', () {
    final converter = InPlaceConverter(CastConverter.instance);

    tc.group('- ints', () {
      final $toInt = converter.value<int>();
      final $toNullableInt = converter.nullable<int>();

      void $platformSensitive(double value, {required bool nullable}) {
        final fn = nullable ? $toNullableInt : $toInt;
        final process = nullable ? 'toNullableInt' : 'toInt';
        try {
          final res = fn(value);
          expect(res, value);
          _unexpectedSuccessIfNonJs(process, res);
        } on TypeError catch (ex) {
          _unexpectedFailureIfJs(process, ex);
        }
      }

      tc.test('- converters are identities', () {
        expect(Converter.isIdentity($toInt), isTrue);
        expect(Converter.isIdentity($toNullableInt), isTrue);
      });

      tc.test('- int', () {
        expect($toInt(5), 5);
        expect($toNullableInt(5), 5);
      });

      tc.test('- double', () async {
        $platformSensitive(5.toDouble(), nullable: false);
        $platformSensitive(5.toDouble(), nullable: true);

        await expectLater(() => $toInt(5.5), _throwsTypeError);
        await expectLater(() => $toNullableInt(5.5), _throwsTypeError);

        $platformSensitive(double.infinity, nullable: false);
        $platformSensitive(double.infinity, nullable: true);

        $platformSensitive(double.negativeInfinity, nullable: false);
        $platformSensitive(double.negativeInfinity, nullable: true);

        await expectLater(() => $toInt(double.nan), _throwsTypeError);
        await expectLater(() => $toNullableInt(double.nan), _throwsTypeError);

        $platformSensitive(-0.0, nullable: false);
        $platformSensitive(-0.0, nullable: true);
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
      });

      tc.test('- Object', () async {
        await expectLater(() => $toInt(Object()), _throwsTypeError);
        await expectLater(() => $toNullableInt(Object()), _throwsTypeError);
      });
    });

    tc.group('- doubles', () {
      final $toDbl = converter.value<double>();
      final $toNullableDbl = converter.nullable<double>();

      void $platformSensitive(int value, {required bool nullable}) {
        final fn = nullable ? $toNullableDbl : $toDbl;
        final process = nullable ? 'toNullableDbl' : 'toDbl';
        try {
          final res = fn(value);
          expect(res, value);
          _unexpectedSuccessIfNonJs(process, res);
        } on TypeError catch (ex) {
          _unexpectedFailureIfJs(process, ex);
        }
      }

      tc.test('- converters are identities', () {
        expect(Converter.isIdentity($toDbl), isTrue);
        expect(Converter.isIdentity($toNullableDbl), isTrue);
      });

      tc.test('- int', () {
        $platformSensitive(5, nullable: false);
        $platformSensitive(5, nullable: true);
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

    tc.group('- lists', () {
      tc.test('- ints (cast)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfInts);

        await expectLater(() => data as List<int>, _throwsTypeError);
        final res = converter.list<int>()(data);
        expect(res, isA<List<int>>());
        expect(res, _listOfInts);
      });

      tc.test('- ints (map)', () async {
        final data = <dynamic>[];
        data.addAll(_listOfInts);

        await expectLater(() => data as List<int>, _throwsTypeError);
        final res = converter.list<int>(_asInt)(data);
        expect(res, isA<List<int>>());
        expect(res, _listOfInts);
      });

      tc.test('- nullable ints', () async {
        final data = <dynamic>[];
        data.addAll(_listOfNullableInts);

        await expectLater(() => data as List<int?>, _throwsTypeError);
        final res = converter.list<int?>(converter.nullable<int>())(data);
        expect(res, isA<List<int?>>());
        expect(res, _listOfNullableInts);
      });

      tc.test('- ints + integral double (cast)', () async {
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

      tc.test('- ints + integral double (map)', () async {
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

      tc.test('- doubles', () async {
        final data = <dynamic>[];
        data.addAll(_listOfDoubles);

        await expectLater(() => data as List<double>, _throwsTypeError);
        final res = converter.list<double>()(data);
        expect(res, isA<List<double>>());
        expect(res, _listOfDoubles);
      });

      tc.test('- nullable doubles', () async {
        final data = <dynamic>[];
        data.addAll(_listOfNullableDoubles);

        await expectLater(() => data as List<double?>, _throwsTypeError);
        final res = converter.list<double?>(converter.nullable<double>())(data);
        expect(res, isA<List<double?>>());
        expect(res, _listOfNullableDoubles);
      });

      tc.test('- doubles + int', () async {
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

    tc.group('- maps', () {
      tc.test('- String / int (cast)', () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfInts);

        await expectLater(() => data as Map<String, int>, _throwsTypeError);
        final res = converter.map<String, int>()(data);
        expect(res, isA<Map<String, int>>());
        expect(res, _mapOfInts);
      });

      tc.test('- String / int (map)', () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfInts);

        await expectLater(() => data as Map<String, int>, _throwsTypeError);
        final res = converter.map<String, int>(vcast: _asInt)(data);
        expect(res, isA<Map<String, int>>());
        expect(res, _mapOfInts);
      });

      tc.test('- String / nullable int', () async {
        final data = <dynamic, dynamic>{};
        data.addAll(_mapOfNullableInts);

        await expectLater(() => data as Map<String, int>, _throwsTypeError);
        final res =
            converter.map<String, int?>(vcast: converter.nullable<int>())(data);
        expect(res, isA<Map<String, int?>>());
        expect(res, _mapOfNullableInts);
      });

      tc.test('- String / ints + integral double (cast)', () async {
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

      tc.test('- String / ints + integral double (map)', () async {
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
  });
}
