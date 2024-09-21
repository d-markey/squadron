// ignore_for_file: file_names

part of '03_converter_test.dart';

// ignore: non_constant_identifier_names
void testCastConverter(TestContext tc) {
  tc.group('- CastConverter', () {
    final converter = CastConverter.instance;

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

    tc.group('- sets', () {
      tc.test('- ints (cast)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfInts);

        await expectLater(() => data as Set<int>, _throwsTypeError);
        final res = converter.set<int>()(data);
        expect(res, isA<Set<int>>());
        expect(res, _listOfInts.toSet());
      });

      tc.test('- ints (map)', () async {
        final data = <dynamic>{};
        data.addAll(_listOfInts);

        await expectLater(() => data as Set<int>, _throwsTypeError);
        final res = converter.set<int>()(data);
        expect(res, isA<Set<int>>());
        expect(res, _listOfInts.toSet());
      });

      tc.test('- nullable ints', () async {
        final data = <dynamic>{};
        data.addAll(_listOfNullableInts);

        await expectLater(() => data as Set<int?>, _throwsTypeError);
        final res = converter.set<int?>(converter.nullable<int>())(data);
        expect(res, isA<Set<int?>>());
        expect(res, _listOfNullableInts.toSet());
      });

      tc.test('- ints + integral double (cast)', () async {
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

      tc.test('- ints + integral double (map)', () async {
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

      tc.test('- doubles', () async {
        final data = <dynamic>{};
        data.addAll(_listOfDoubles);

        await expectLater(() => data as Set<double>, _throwsTypeError);
        final res = converter.set<double>()(data);
        expect(res, isA<Set<double>>());
        expect(res, _listOfDoubles.toSet());
      });

      tc.test('- nullable doubles', () async {
        final data = <dynamic>{};
        data.addAll(_listOfNullableDoubles);

        await expectLater(() => data as Set<double?>, _throwsTypeError);
        final res = converter.set<double?>(converter.nullable<double>())(data);
        expect(res, isA<Set<double?>>());
        expect(res, _listOfNullableDoubles.toSet());
      });

      tc.test('- doubles + int', () async {
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

    tc.group('- typed data', () {
      final intData = [
        0, // 8 bits
        1,
        2,
        254,
        256, // 16 bits
        257,
        65534,
        65536, // 32 bits
        65537,
        4294967294,
        4294967296, //64 bits
        4294967297,
        4294967298,
      ];

      final dblData = [
        double.nan,
        double.negativeInfinity,
        -double.maxFinite,
        -math.pi - double.minPositive,
        -0.0,
        0.0,
        double.minPositive,
        math.pi,
        double.maxFinite,
        double.infinity,
      ];

      final tds = {
        ByteData: converter.typedData<ByteData>(),
        Uint8ClampedList: converter.typedData<Uint8ClampedList>(),
        Uint8List: converter.typedData<Uint8List>(),
        Int8List: converter.typedData<Int8List>(),
        Uint16List: converter.typedData<Uint16List>(),
        Int16List: converter.typedData<Int16List>(),
        Uint32List: converter.typedData<Uint32List>(),
        Int32List: converter.typedData<Int32List>(),
        Int32x4List: converter.typedData<Int32x4List>(),
        Uint64List: converter.typedData<Uint64List>(),
        Int64List: converter.typedData<Int64List>(),
        Float32List: converter.typedData<Float32List>(),
        Float32x4List: converter.typedData<Float32x4List>(),
        Float64List: converter.typedData<Float64List>(),
        Float64x2List: converter.typedData<Float64x2List>(),
      };

      Future<void> $test<T extends TypedData>(dynamic input, T output) async {
        final fn = tds[T]! as Cast<T>;
        final process = 'converter.td<$T>';

        final nres = converter.nullable<T>(fn)(null);
        expect(nres, isNull);

        try {
          final res = fn(null);
          throw unexpectedSuccess(process, res);
        } on TypeError catch (_) {
          // expected error
        }

        await expectLater(() => fn(Object()), _throwsTypeError);

        if (input != null && input is! ByteBuffer) {
          for (var entry in tds.entries) {
            final efn = entry.value;
            if (entry.key == T) {
              expect(efn(input), output);
            } else {
              await expectLater(() => efn(input), _throwsTypeError);
            }
          }
        }
      }

      tc.test('- ByteData', () async {
        final input = ByteData.view(Uint8List.fromList(intData).buffer);

        await $test<ByteData>(input, input);
        await $test<ByteData>(input.buffer, input);
      });

      tc.test('- Uint8ClampedList', () async {
        final input = Uint8ClampedList.fromList(intData);

        await $test<Uint8ClampedList>(input, input);
        await $test<Uint8ClampedList>(input.buffer, input);
      });

      tc.test('- Uint8List', () async {
        final input = Uint8List.fromList(intData);

        await $test<Uint8List>(input, input);
        await $test<Uint8List>(input.buffer, input);
      });

      tc.test('- Int8List', () async {
        final input = Int8List.fromList(intData);

        await $test<Int8List>(input, input);
        await $test<Int8List>(input.buffer, input);
      });

      tc.test('- Uint16List', () async {
        final input = Uint16List.fromList(intData);

        await $test<Uint16List>(input, input);
        await $test<Uint16List>(input.buffer, input);
      });

      tc.test('- Int16List', () async {
        final input = Int16List.fromList(intData);

        await $test<Int16List>(input, input);
        await $test<Int16List>(input.buffer, input);
      });

      tc.test('- Uint32List', () async {
        final input = Uint32List.fromList(intData);

        await $test<Uint32List>(input, input);
        await $test<Uint32List>(input.buffer, input);
      });

      tc.test('- Int32List', () async {
        final input = Int32List.fromList(intData);

        await $test<Int32List>(input, input);
        await $test<Int32List>(input.buffer, input);
      });

      tc.test('- Int32x4List', () async {
        final rnd = math.Random();
        final input = Int32x4List(17);
        for (var i = 0; i < input.length; i++) {
          input[i] = Int32x4(
            rnd.nextInt(0x100000000),
            rnd.nextInt(0x100000000),
            rnd.nextInt(0x100000000),
            rnd.nextInt(0x100000000),
          );
        }

        await $test<Int32x4List>(input, input);
        await $test<Int32x4List>(input.buffer, input);
      });

      tc.test('- Uint64List', () async {
        final input = Uint64List.fromList(intData);

        await $test<Uint64List>(input, input);
        await $test<Uint64List>(input.buffer, input);
      }, skip: tc.clientPlatform.isJs);

      tc.test('- Int64List', () async {
        final input = Int64List.fromList(intData);

        await $test<Int64List>(input, input);
        await $test<Int64List>(input.buffer, input);
      }, skip: tc.clientPlatform.isJs);

      tc.test('- Float32List', () async {
        final input = Float32List.fromList(dblData);

        await $test<Float32List>(input, input);
        await $test<Float32List>(input.buffer, input);
      });

      tc.test('- Float32x4List', () async {
        final rnd = math.Random();
        final input = Float32x4List(7);
        for (var i = 0; i < input.length; i++) {
          input[i] = Float32x4(
            rnd.nextDouble(),
            rnd.nextDouble(),
            rnd.nextDouble(),
            rnd.nextDouble(),
          );
        }

        await $test<Float32x4List>(input, input);
        await $test<Float32x4List>(input.buffer, input);
      });

      tc.test('- Float64List', () async {
        final input = Float64List.fromList(dblData);

        await $test<Float64List>(input, input);
        await $test<Float64List>(input.buffer, input);
      });

      tc.test('- Float64x2List', () async {
        final rnd = math.Random();
        final input = Float64x2List(7);
        for (var i = 0; i < input.length; i++) {
          input[i] = Float64x2(rnd.nextDouble(), rnd.nextDouble());
        }

        await $test<Float64x2List>(input, input);
        await $test<Float64x2List>(input.buffer, input);
      });
    });
  });
}
