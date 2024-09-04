// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/test_context.dart';

void main() {
  TestContext.init('').then(execute);
  // TestContext.init('', TestPlatform.wasm).then(execute);
}

String testScript = '03_converter_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.run(() {
    tc.group("- CastConverter", () {
      final converter = CastConverter.instance;

      tc.test('int', () async {
        final toInt = converter.v<int>();
        expect(CastConverter.isIdentity(toInt), isTrue);
        expect(toInt(5), 5);
        await expectLater(() => toInt(null), throwsA(isA<TypeError>()));
        await expectLater(() => toInt(5.0), throwsA(isA<TypeError>()));
        await expectLater(() => toInt(5.5), throwsA(isA<TypeError>()));
      });

      tc.test('int?', () async {
        final toNullableInt = converter.nv<int>();
        expect(CastConverter.isIdentity(toNullableInt), isTrue);
        expect(toNullableInt(5), 5);
        expect(toNullableInt(null), isNull);
        await expectLater(() => toNullableInt(5.0), throwsA(isA<TypeError>()));
        await expectLater(() => toNullableInt(5.5), throwsA(isA<TypeError>()));
      });

      tc.test('double', () async {
        final toDbl = converter.v<double>();
        expect(CastConverter.isIdentity(toDbl), isTrue);
        await expectLater(() => toDbl(5), throwsA(isA<TypeError>()));
        await expectLater(() => toDbl(null), throwsA(isA<TypeError>()));
        expect(toDbl(5.0), 5.0);
        expect(toDbl(5.5), 5.5);
      });

      tc.test('double?', () async {
        final toNullableDbl = converter.v<double?>();
        expect(CastConverter.isIdentity(toNullableDbl), isTrue);
        await expectLater(() => toNullableDbl(5), throwsA(isA<TypeError>()));
        expect(toNullableDbl(null), isNull);
        expect(toNullableDbl(5.0), 5.0);
        expect(toNullableDbl(5.5), 5.5);
      });
    });

    tc.group("- NumConverter", () {
      final converter = NumConverter.instance;

      tc.test('int', () async {
        final toInt = converter.v<int>();
        expect(CastConverter.isIdentity(toInt), isFalse);
        expect(toInt(5), equals(5));
        await expectLater(() => toInt(null), throwsA(isA<TypeError>()));
        expect(toInt(5.0), equals(5));
        expect(toInt(5.5), equals(5)); // should throw really
      });

      tc.test('int?', () async {
        final toNullableInt = converter.nv<int>();
        expect(CastConverter.isIdentity(toNullableInt), isFalse);
        expect(toNullableInt(5), equals(5));
        expect(toNullableInt(null), isNull);
        expect(toNullableInt(5.0), equals(5));
        expect(toNullableInt(5.5), equals(5)); // should throw really
      });
    });
  });
}
