// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';

void main() {
  TestContext.init('~').then(execute);
}

String testScript = '03_converter_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  final throwsTypeError = failsWith<TypeError>();
  final isInfinite = anyOf(double.infinity, double.negativeInfinity);

  tc.run(() {
    tc.group('- Converters', () {
      tc.group('- CastConverter', () {
        final converter = CastConverter.instance;

        tc.group('- ints', () {
          final toInt = converter.v<int>();
          final toNullableInt = converter.nv<int>();

          void $platformSensitive(double value, {required bool nullable}) {
            final fn = nullable ? toNullableInt : toInt;
            final process = nullable ? 'toNullableInt' : 'toInt';
            try {
              final res = fn(value);
              if (!tc.clientPlatform.isJs) {
                throw unexpectedSuccess(process, res);
              } else {
                expect(res, value);
              }
            } on TypeError catch (ex) {
              if (tc.clientPlatform.isJs) {
                throw unexpectedFailure(process, ex);
              }
            }
          }

          tc.test('- converters are identities', () {
            expect(Converter.isIdentity(toInt), isTrue);
            expect(Converter.isIdentity(toNullableInt), isTrue);
          });

          tc.test('- int values', () {
            expect(toInt(5), 5);
            expect(toNullableInt(5), 5);
          });

          tc.test(
              '- doubles values (fail except for non-fractional doubles on JavaScript platforms)',
              () async {
            $platformSensitive(5.toDouble(), nullable: false);
            $platformSensitive(5.toDouble(), nullable: true);

            await expectLater(() => toInt(5.5), throwsTypeError);
            await expectLater(() => toNullableInt(5.5), throwsTypeError);

            $platformSensitive(double.infinity, nullable: false);
            $platformSensitive(double.infinity, nullable: true);

            $platformSensitive(double.negativeInfinity, nullable: false);
            $platformSensitive(double.negativeInfinity, nullable: true);

            await expectLater(() => toInt(double.nan), throwsTypeError);
            await expectLater(() => toNullableInt(double.nan), throwsTypeError);

            $platformSensitive(-0.0, nullable: false);
            $platformSensitive(-0.0, nullable: true);
          });

          tc.test('- null values', () async {
            await expectLater(() => toInt(null), throwsTypeError);
            expect(toNullableInt(null), isNull);
          });

          tc.test('- bool values', () async {
            await expectLater(() => toInt(true), throwsTypeError);
            await expectLater(() => toNullableInt(true), throwsTypeError);
          });

          tc.test('- String values', () async {
            await expectLater(() => toInt('1'), throwsTypeError);
            await expectLater(() => toNullableInt('1'), throwsTypeError);
          });

          tc.test('- non-number values', () async {
            await expectLater(() => toInt(Object()), throwsTypeError);
            await expectLater(() => toNullableInt(Object()), throwsTypeError);
          });
        });

        tc.group('- doubles', () {
          final toDbl = converter.v<double>();
          final toNullableDbl = converter.nv<double>();

          void $platformSensitive(int value, {required bool nullable}) {
            final fn = nullable ? toNullableDbl : toDbl;
            final process = nullable ? 'toNullableDbl' : 'toDbl';
            try {
              final res = fn(value);
              if (!tc.clientPlatform.isJs) {
                throw unexpectedSuccess(process, res);
              } else {
                expect(res, value);
              }
            } on TypeError catch (ex) {
              if (tc.clientPlatform.isJs) {
                throw unexpectedFailure(process, ex);
              }
            }
          }

          tc.test('- converters are identities', () {
            expect(Converter.isIdentity(toDbl), isTrue);
            expect(Converter.isIdentity(toNullableDbl), isTrue);
          });

          tc.test('- int values (fail except on JavaScript platforms)', () {
            $platformSensitive(5, nullable: false);
            $platformSensitive(5, nullable: true);
          });

          tc.test('- doubles values', () {
            expect(toDbl(5.5), 5.5);
            expect(toNullableDbl(5.5), 5.5);

            expect(toDbl(-0.0), -0.0);
            expect(toNullableDbl(-0.0), -0.0);

            expect(toDbl(double.infinity), isInfinite);
            expect(toNullableDbl(double.infinity), isInfinite);

            expect(toDbl(double.negativeInfinity), isInfinite);
            expect(toNullableDbl(double.negativeInfinity), isInfinite);

            expect(toDbl(double.nan), isNaN);
            expect(toNullableDbl(double.nan), isNaN);
          });

          tc.test('- null values', () async {
            await expectLater(() => toDbl(null), throwsTypeError);
            expect(toNullableDbl(null), isNull);
          });

          tc.test('- bool values', () async {
            await expectLater(() => toDbl(true), throwsTypeError);
            await expectLater(() => toNullableDbl(true), throwsTypeError);
          });

          tc.test('- String values', () async {
            await expectLater(() => toDbl('1'), throwsTypeError);
            await expectLater(() => toNullableDbl('1'), throwsTypeError);
          });

          tc.test('- non-number values', () async {
            await expectLater(() => toDbl(Object()), throwsTypeError);
            await expectLater(() => toNullableDbl(Object()), throwsTypeError);
          });
        });

        tc.group('- lists', () {
          tc.test('- ints (cast)', () async {
            final data = <dynamic>[];
            data.addAll([1, 2, 3, 4]);

            await expectLater(() => data as List<int>, throwsTypeError);
            final res = converter.l<int>()(data);
            expect(res, isA<List<int>>());
            expect(res, data);
          });

          tc.test('- ints (map)', () async {
            final data = <dynamic>[];
            data.addAll([1, 2, 3, 4]);

            await expectLater(() => data as List<int>, throwsTypeError);
            final res = converter.l<int>((x) => x as int)(data);
            expect(res, isA<List<int>>());
            expect(res, data);
          });

          tc.test('- nullable ints', () async {
            final data = <dynamic>[];
            data.addAll([1, 2, null, 4]);

            await expectLater(() => data as List<int?>, throwsTypeError);
            final res = converter.nl<int>()(data);
            expect(res, isA<List<int?>>());
            expect(res, data);
          });

          tc.test('- with integral double (cast)', () async {
            final data = <dynamic>[];
            data.addAll([1, 2, 3.toDouble(), 4]);

            await expectLater(() => data as List<int>, throwsTypeError);
            final res = converter.l<int>()(data);
            expect(res, isA<List<int>>()); // conversion succeeds
            try {
              expect(res, data);
              if (Squadron.platformType.isJs) {
                // integral double is int on JavaScript platforms
              } else {
                throw unexpectedSuccess(
                    'conversion of a list with integral double', res);
              }
            } on TypeError catch (ex) {
              if (!Squadron.platformType.isJs) {
                // integral double is NOT int on non-JavaScript platforms
              } else {
                throw unexpectedFailure(
                    'conversion of a list with integral double', ex);
              }
            }
          });

          tc.test('- with integral double (map)', () async {
            final data = <dynamic>[];
            data.addAll([1, 2, 3.toDouble(), 4]);

            await expectLater(() => data as List<int>, throwsTypeError);
            try {
              final res = converter.l<int>((x) => x as int)(data);
              if (Squadron.platformType.isJs) {
                // integral double is int on JavaScript platforms
                expect(res, data);
              } else {
                throw unexpectedSuccess(
                    'conversion of a list with integral double', res);
              }
            } on TypeError catch (ex) {
              if (!Squadron.platformType.isJs) {
                // integral double is NOT int on non-JavaScript platforms
              } else {
                throw unexpectedFailure(
                    'conversion of a list with integral double', ex);
              }
            }
          });

          tc.test('- doubles', () async {
            final data = <dynamic>[];
            data.addAll([1.1, 2.2, 3.3, 4.4]);

            await expectLater(() => data as List<double>, throwsTypeError);
            final res = converter.l<double>()(data);
            expect(res, isA<List<double>>());
            expect(res, data);
          });

          tc.test('- nullable doubles', () async {
            final data = <dynamic>[];
            data.addAll([1.1, 2.2, null, 4.4]);

            await expectLater(() => data as List<double?>, throwsTypeError);
            final res = converter.nl<double>()(data);
            expect(res, isA<List<double?>>());
            expect(res, data);
          });

          tc.test('- with int', () async {
            final data = <dynamic>[];
            data.addAll([1.1, 2.2, 3.toInt(), 4.4]);

            await expectLater(() => data as List<double>, throwsTypeError);
            final res = converter.l<double>()(data);
            expect(res, isA<List<double>>()); // conversion succeeds
            try {
              expect(res, data);
              if (Squadron.platformType.isJs) {
                // int is double on JavaScript platforms
              } else {
                throw unexpectedSuccess('conversion of a list with int', data);
              }
            } on TypeError catch (ex) {
              if (!Squadron.platformType.isJs) {
                // int is NOT double on non-JavaScript platforms
              } else {
                throw unexpectedFailure('conversion of a list with int', ex);
              }
            }
          });
        });

        tc.group('- maps', () {
          tc.test('- Strings / ints (cast)', () async {
            final data = <dynamic, dynamic>{};
            data.addAll({'one': 1, 'two': 2, 'three': 3});

            await expectLater(() => data as Map<String, int>, throwsTypeError);
            final res = converter.m<String, int>()(data);
            expect(res, isA<Map<String, int>>());
            expect(res, data);
          });

          tc.test('- String / ints (map)', () async {
            final data = <dynamic, dynamic>{};
            data.addAll({'one': 1, 'two': 2, 'three': 3});

            await expectLater(() => data as Map<String, int>, throwsTypeError);
            final res = converter.m<String, int>(vcast: (x) => x as int)(data);
            expect(res, isA<Map<String, int>>());
            expect(res, data);
          });

          tc.test('- String / nullable int', () async {
            final data = <dynamic, dynamic>{};
            data.addAll({'one': 1, '': null, 'three': 3});

            await expectLater(() => data as Map<String, int>, throwsTypeError);
            final res = converter.nm<String, int?>()(data);
            expect(res, isA<Map<String, int?>>());
            expect(res, data);
          });

          tc.test('- String / integral double (cast)', () async {
            final data = <dynamic, dynamic>{};
            data.addAll({
              'one': 1.toDouble(),
              'two': 2.toDouble(),
              'three': 3.toDouble()
            });

            await expectLater(() => data as Map<String, int>, throwsTypeError);
            final res = converter.m<String, int>()(data);
            expect(res, isA<Map<String, int>>());
            try {
              expect(res, data);
              if (Squadron.platformType.isJs) {
                // integral double is int on JavaScript platforms
              } else {
                throw unexpectedSuccess(
                    'conversion of a map with integral double', res);
              }
            } on TypeError catch (ex) {
              if (!Squadron.platformType.isJs) {
                // integral double is NOT int on non-JavaScript platforms
              } else {
                throw unexpectedFailure(
                    'conversion of a map with integral double', ex);
              }
            }
          });

          tc.test('- String / integral double (map)', () async {
            final data = <dynamic, dynamic>{};
            data.addAll({
              'one': 1.toDouble(),
              'two': 2.toDouble(),
              'three': 3.toDouble()
            });

            await expectLater(() => data as Map<String, int>, throwsTypeError);
            try {
              final res =
                  converter.m<String, int>(vcast: (x) => x as int)(data);
              if (Squadron.platformType.isJs) {
                // integral double is int on JavaScript platforms
                expect(res, isA<Map<String, int>>());
                expect(res, data);
              } else {
                throw unexpectedSuccess(
                    'conversion of a map with integral double', res);
              }
            } on TypeError catch (ex) {
              if (!Squadron.platformType.isJs) {
                // integral double is NOT int on non-JavaScript platforms
              } else {
                throw unexpectedFailure(
                    'conversion of a map with integral double', ex);
              }
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
            ByteData: converter.td<ByteData>(),
            Uint8ClampedList: converter.td<Uint8ClampedList>(),
            Uint8List: converter.td<Uint8List>(),
            Int8List: converter.td<Int8List>(),
            Uint16List: converter.td<Uint16List>(),
            Int16List: converter.td<Int16List>(),
            Uint32List: converter.td<Uint32List>(),
            Int32List: converter.td<Int32List>(),
            Int32x4List: converter.td<Int32x4List>(),
            Uint64List: converter.td<Uint64List>(),
            Int64List: converter.td<Int64List>(),
            Float32List: converter.td<Float32List>(),
            Float32x4List: converter.td<Float32x4List>(),
            Float64List: converter.td<Float64List>(),
            Float64x2List: converter.td<Float64x2List>(),
          };

          final ntds = {
            ByteData: converter.ntd<ByteData>(),
            Uint8ClampedList: converter.ntd<Uint8ClampedList>(),
            Uint8List: converter.ntd<Uint8List>(),
            Int8List: converter.ntd<Int8List>(),
            Uint16List: converter.ntd<Uint16List>(),
            Int16List: converter.ntd<Int16List>(),
            Uint32List: converter.ntd<Uint32List>(),
            Int32List: converter.ntd<Int32List>(),
            Int32x4List: converter.ntd<Int32x4List>(),
            Uint64List: converter.ntd<Uint64List>(),
            Int64List: converter.ntd<Int64List>(),
            Float32List: converter.ntd<Float32List>(),
            Float32x4List: converter.ntd<Float32x4List>(),
            Float64List: converter.ntd<Float64List>(),
            Float64x2List: converter.ntd<Float64x2List>(),
          };

          Future<void> $test<T extends TypedData>(dynamic input, T output,
              {required bool nullable}) async {
            final fn = (nullable ? ntds[T] : tds[T])!;
            final process = nullable ? 'converter.ntd<$T>' : 'converter.td<$T>';

            try {
              final res = fn(null);
              if (nullable) {
                expect(res, isNull);
              } else {
                throw unexpectedSuccess(process, res);
              }
            } on TypeError catch (ex) {
              if (nullable) {
                throw unexpectedFailure(process, ex);
              }
            }

            await expectLater(() => fn(Object()), throwsTypeError);

            if (input != null && input is! ByteBuffer) {
              for (var entry in ntds.entries.followedBy(tds.entries)) {
                final efn = entry.value;
                if (entry.key == T) {
                  expect(efn(input), output);
                } else {
                  await expectLater(() => efn(input), throwsTypeError);
                }
              }
            }
          }

          tc.test('- ByteData', () async {
            final input = ByteData.view(Uint8List.fromList(intData).buffer);

            await $test<ByteData>(input, input, nullable: false);
            await $test<ByteData>(input, input, nullable: true);

            await $test<ByteData>(input.buffer, input, nullable: false);
            await $test<ByteData>(input.buffer, input, nullable: true);
          });

          tc.test('- Uint8ClampedList', () async {
            final input = Uint8ClampedList.fromList(intData);

            await $test<Uint8ClampedList>(input, input, nullable: false);
            await $test<Uint8ClampedList>(input, input, nullable: true);

            await $test<Uint8ClampedList>(input.buffer, input, nullable: false);
            await $test<Uint8ClampedList>(input.buffer, input, nullable: true);
          });

          tc.test('- Uint8List', () async {
            final input = Uint8List.fromList(intData);

            await $test<Uint8List>(input, input, nullable: false);
            await $test<Uint8List>(input, input, nullable: true);

            await $test<Uint8List>(input.buffer, input, nullable: false);
            await $test<Uint8List>(input.buffer, input, nullable: true);
          });

          tc.test('- Int8List', () async {
            final input = Int8List.fromList(intData);

            await $test<Int8List>(input, input, nullable: false);
            await $test<Int8List>(input, input, nullable: true);

            await $test<Int8List>(input.buffer, input, nullable: false);
            await $test<Int8List>(input.buffer, input, nullable: true);
          });

          tc.test('- Uint16List', () async {
            final input = Uint16List.fromList(intData);

            await $test<Uint16List>(input, input, nullable: false);
            await $test<Uint16List>(input, input, nullable: true);

            await $test<Uint16List>(input.buffer, input, nullable: false);
            await $test<Uint16List>(input.buffer, input, nullable: true);
          });

          tc.test('- Int16List', () async {
            final input = Int16List.fromList(intData);

            await $test<Int16List>(input, input, nullable: false);
            await $test<Int16List>(input, input, nullable: true);

            await $test<Int16List>(input.buffer, input, nullable: false);
            await $test<Int16List>(input.buffer, input, nullable: true);
          });

          tc.test('- Uint32List', () async {
            final input = Uint32List.fromList(intData);

            await $test<Uint32List>(input, input, nullable: false);
            await $test<Uint32List>(input, input, nullable: true);

            await $test<Uint32List>(input.buffer, input, nullable: false);
            await $test<Uint32List>(input.buffer, input, nullable: true);
          });

          tc.test('- Int32List', () async {
            final input = Int32List.fromList(intData);

            await $test<Int32List>(input, input, nullable: false);
            await $test<Int32List>(input, input, nullable: true);

            await $test<Int32List>(input.buffer, input, nullable: false);
            await $test<Int32List>(input.buffer, input, nullable: true);
          });

          tc.test('- Int32List', () async {
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

            await $test<Int32x4List>(input, input, nullable: false);
            await $test<Int32x4List>(input, input, nullable: true);

            await $test<Int32x4List>(input.buffer, input, nullable: false);
            await $test<Int32x4List>(input.buffer, input, nullable: true);
          });

          tc.test('- Uint64List', () async {
            final input = Uint64List.fromList(intData);

            await $test<Uint64List>(input, input, nullable: false);
            await $test<Uint64List>(input, input, nullable: true);

            await $test<Uint64List>(input.buffer, input, nullable: false);
            await $test<Uint64List>(input.buffer, input, nullable: true);
          }, skip: tc.clientPlatform.isJs);

          tc.test('- Int64List', () async {
            final input = Int64List.fromList(intData);

            await $test<Int64List>(input, input, nullable: false);
            await $test<Int64List>(input, input, nullable: true);

            await $test<Int64List>(input.buffer, input, nullable: false);
            await $test<Int64List>(input.buffer, input, nullable: true);
          }, skip: tc.clientPlatform.isJs);

          tc.test('- Float32List', () async {
            final input = Float32List.fromList(dblData);

            await $test<Float32List>(input, input, nullable: false);
            await $test<Float32List>(input, input, nullable: true);

            await $test<Float32List>(input.buffer, input, nullable: false);
            await $test<Float32List>(input.buffer, input, nullable: true);
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

            await $test<Float32x4List>(input, input, nullable: false);
            await $test<Float32x4List>(input, input, nullable: true);

            await $test<Float32x4List>(input.buffer, input, nullable: false);
            await $test<Float32x4List>(input.buffer, input, nullable: true);
          });

          tc.test('- Float64List', () async {
            final input = Float64List.fromList(dblData);

            await $test<Float64List>(input, input, nullable: false);
            await $test<Float64List>(input, input, nullable: true);

            await $test<Float64List>(input.buffer, input, nullable: false);
            await $test<Float64List>(input.buffer, input, nullable: true);
          });

          tc.test('- Float64x2List', () async {
            final rnd = math.Random();
            final input = Float64x2List(7);
            for (var i = 0; i < input.length; i++) {
              input[i] = Float64x2(rnd.nextDouble(), rnd.nextDouble());
            }

            await $test<Float64x2List>(input, input, nullable: false);
            await $test<Float64x2List>(input, input, nullable: true);

            await $test<Float64x2List>(input.buffer, input, nullable: false);
            await $test<Float64x2List>(input.buffer, input, nullable: true);
          });
        });
      });

      tc.group("- NumConverter", () {
        final converter = NumConverter.instance;

        tc.group('- ints', () {
          final toInt = converter.v<int>();
          final toNullableInt = converter.nv<int>();

          tc.test('- converters are not identities', () {
            expect(Converter.isIdentity(toInt), isFalse);
            expect(Converter.isIdentity(toNullableInt), isFalse);
          });

          tc.test('- int values', () {
            expect(toInt(5), 5);
            expect(toNullableInt(5), 5);
          });

          tc.test('- doubles values', () async {
            expect(toInt(5.toDouble()), 5);
            expect(toNullableInt(5.toDouble()), 5);

            await expectLater(() => toInt(5.5), throwsTypeError);
            await expectLater(() => toNullableInt(5.5), throwsTypeError);

            await expectLater(() => toInt(double.infinity), throwsTypeError);
            await expectLater(
                () => toNullableInt(double.infinity), throwsTypeError);

            await expectLater(
                () => toInt(double.negativeInfinity), throwsTypeError);
            await expectLater(
                () => toNullableInt(double.negativeInfinity), throwsTypeError);

            await expectLater(() => toInt(double.nan), throwsTypeError);
            await expectLater(() => toNullableInt(double.nan), throwsTypeError);

            expect(toInt(-0.0), 0);
            expect(toNullableInt(-0.0), 0);
          });

          tc.test('- null values', () async {
            await expectLater(() => toInt(null), throwsTypeError);
            expect(toNullableInt(null), isNull);
          });

          tc.test('- bool values', () async {
            await expectLater(() => toInt(true), throwsTypeError);
            await expectLater(() => toNullableInt(true), throwsTypeError);
          });

          tc.test('- String values', () async {
            await expectLater(() => toInt('1'), throwsTypeError);
            await expectLater(() => toNullableInt('1'), throwsTypeError);
          });

          tc.test('- non-number values', () async {
            await expectLater(() => toInt(Object()), throwsTypeError);
            await expectLater(() => toNullableInt(Object()), throwsTypeError);
          });
        });

        tc.group('- doubles', () {
          final toDbl = converter.v<double>();
          final toNullableDbl = converter.nv<double>();

          tc.test('- converters are not identities', () {
            expect(Converter.isIdentity(toDbl), isFalse);
            expect(Converter.isIdentity(toNullableDbl), isFalse);
          });

          tc.test('- int values', () {
            expect(toDbl(5.toInt()), 5);
            expect(toNullableDbl(5.toInt()), 5);
          });

          tc.test('- doubles values', () {
            expect(toDbl(5.5), 5.5);
            expect(toNullableDbl(5.5), 5.5);

            expect(toDbl(-0.0), -0.0);
            expect(toNullableDbl(-0.0), -0.0);

            expect(toDbl(double.infinity), isInfinite);
            expect(toNullableDbl(double.infinity), isInfinite);

            expect(toDbl(double.negativeInfinity), isInfinite);
            expect(toNullableDbl(double.negativeInfinity), isInfinite);

            expect(toDbl(double.nan), isNaN);
            expect(toNullableDbl(double.nan), isNaN);
          });

          tc.test('- null values', () async {
            await expectLater(() => toDbl(null), throwsTypeError);
            expect(toNullableDbl(null), isNull);
          });

          tc.test('- bool values', () async {
            await expectLater(() => toDbl(true), throwsTypeError);
            await expectLater(() => toNullableDbl(true), throwsTypeError);
          });

          tc.test('- String values', () async {
            await expectLater(() => toDbl('1'), throwsTypeError);
            await expectLater(() => toNullableDbl('1'), throwsTypeError);
          });

          tc.test('- non-number values', () async {
            await expectLater(() => toDbl(Object()), throwsTypeError);
            await expectLater(() => toNullableDbl(Object()), throwsTypeError);
          });
        });

        tc.group('- lists', () {
          tc.test('- ints (cast)', () async {
            final data = <dynamic>[];
            data.addAll([1, 2, 3, 4]);

            await expectLater(() => data as List<int>, throwsTypeError);
            final res = converter.l<int>()(data);
            expect(res, isA<List<int>>());
            expect(res, data);
          });

          tc.test('- ints (map)', () async {
            final data = <dynamic>[];
            data.addAll([1, 2, 3, 4]);

            final res = converter.l<int>((x) => x as int)(data);
            expect(res, isA<List<int>>());
            expect(res, data);
          });

          tc.test('- nullable ints', () async {
            final data = <dynamic>[];
            data.addAll([1, 2, null, 4]);

            await expectLater(() => data as List<int?>, throwsTypeError);
            final res = converter.nl<int>()(data);
            expect(res, isA<List<int?>>());
            expect(res, data);
          });

          tc.test('- with integral double (cast)', () async {
            final data = <dynamic>[];
            data.addAll([1, 2, 3.toDouble(), 4]);

            await expectLater(() => data as List<int>, throwsTypeError);
            final res = converter.l<int>()(data);
            expect(res, isA<List<int>>()); // conversion succeeds
            expect(res, data);
          });

          tc.test('- with integral double (map)', () async {
            final data = <dynamic>[];
            data.addAll([1, 2, 3.toDouble(), 4]);

            await expectLater(() => data as List<int>, throwsTypeError);
            try {
              final res = converter.l<int>((x) => x as int)(data);
              if (Squadron.platformType.isJs) {
                // integral double is int on JavaScript platforms
                expect(res, data);
              } else {
                throw unexpectedSuccess(
                    'conversion of a list with integral double', res);
              }
            } on TypeError catch (ex) {
              if (!Squadron.platformType.isJs) {
                // integral double is NOT int on non-JavaScript platforms
              } else {
                throw unexpectedFailure(
                    'conversion of a list with integral double', ex);
              }
            }
          });

          tc.test('- doubles', () async {
            final data = <dynamic>[];
            data.addAll([1.1, 2.2, 3.3, 4.4]);

            await expectLater(() => data as List<double>, throwsTypeError);
            final res = converter.l<double>()(data);
            expect(res, isA<List<double>>());
            expect(res, data);
          });

          tc.test('- nullable doubles', () async {
            final data = <dynamic>[];
            data.addAll([1.1, 2.2, null, 4.4]);

            await expectLater(() => data as List<double?>, throwsTypeError);
            final res = converter.nl<double>()(data);
            expect(res, isA<List<double?>>());
            expect(res, data);
          });

          tc.test('- with int', () async {
            final data = <dynamic>[];
            data.addAll([1.1, 2.2, 3.toInt(), 4.4]);

            await expectLater(() => data as List<double>, throwsTypeError);
            final res = converter.l<double>()(data);
            expect(res, isA<List<double>>()); // conversion succeeds
            expect(res, data);
          });
        });

        tc.group('- maps', () {
          tc.test('- Strings / ints (cast)', () async {
            final data = <dynamic, dynamic>{};
            data.addAll({'one': 1, 'two': 2, 'three': 3});

            await expectLater(() => data as Map<String, int>, throwsTypeError);
            final res = converter.m<String, int>()(data);
            expect(res, isA<Map<String, int>>());
            expect(res, data);
          });

          tc.test('- String / ints (map)', () async {
            final data = <dynamic, dynamic>{};
            data.addAll({'one': 1, 'two': 2, 'three': 3});

            await expectLater(() => data as Map<String, int>, throwsTypeError);
            final res = converter.m<String, int>(vcast: (x) => x as int)(data);
            expect(res, isA<Map<String, int>>());
            expect(res, data);
          });

          tc.test('- String / nullable int', () async {
            final data = <dynamic, dynamic>{};
            data.addAll({'one': 1, '': null, 'three': 3});

            await expectLater(() => data as Map<String, int>, throwsTypeError);
            final res = converter.nm<String, int?>()(data);
            expect(res, isA<Map<String, int?>>());
            expect(res, data);
          });

          tc.test('- String / integral double (cast)', () async {
            final data = <dynamic, dynamic>{};
            data.addAll({
              'one': 1.toDouble(),
              'two': 2.toDouble(),
              'three': 3.toDouble()
            });

            await expectLater(() => data as Map<String, int>, throwsTypeError);
            final res = converter.m<String, int>()(data);
            expect(res, isA<Map<String, int>>());
            expect(res, data);
          });

          tc.test('- String / integral double (map)', () async {
            final data = <dynamic, dynamic>{};
            data.addAll({
              'one': 1.toDouble(),
              'two': 2.toDouble(),
              'three': 3.toDouble()
            });

            await expectLater(() => data as Map<String, int>, throwsTypeError);
            try {
              final res =
                  converter.m<String, int>(vcast: (x) => x as int)(data);
              if (Squadron.platformType.isJs) {
                // integral double is int on JavaScript platforms
                expect(res, isA<Map<String, int>>());
                expect(res, data);
              } else {
                throw unexpectedSuccess(
                    'conversion of a map with integral double', res);
              }
            } on TypeError catch (ex) {
              if (!Squadron.platformType.isJs) {
                // integral double is NOT int on non-JavaScript platforms
              } else {
                throw unexpectedFailure(
                    'conversion of a map with integral double', ex);
              }
            }
          });
        });
      });
    });
  });
}
