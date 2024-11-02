// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import '03_converter_test__list_features.dart';
import '03_converter_test__map_features.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';

part '03_converter_test_cast.dart';
part '03_converter_test_cast_in_place.dart';
part '03_converter_test_cast_lazy_in_place.dart';
part '03_converter_test_num.dart';
part '03_converter_test_num_in_place.dart';
part '03_converter_test_num_lazy_in_place.dart';

void main() {
  TestContext.init('~').then(execute);
}

String testScript = '03_converter_test.dart';

final _listOfInts = [1, 2, 3, 4];
final _listOfIntsWithIntegralDouble = [1, 2, 3.toDouble(), 4];
final _listOfNullableInts = [1, 2, null, 4];

final _listOfDoubles = [1.1, 2.2, 3.3, 3.4];
final _listOfDoublesWithInt = [1.1, 2.2, 3.toInt(), 4.4];
final _listOfNullableDoubles = [1.1, 2.2, null, 4.4];

final _mapOfInts = {
  'one': 1,
  'two': 2,
  'three': 3,
};
final _mapOfNullableInts = {
  'one': 1,
  '': null,
  'three': 3,
};
final _mapOfIntsWithIntegralDouble = {
  'one': 1,
  'two': 2.toDouble(),
  'three': 3,
};

final _throwsTypeError = failsWith<TypeError>();
final _isInfinite = anyOf(double.infinity, double.negativeInfinity);

int _asInt(dynamic x) => x as int;

void _unexpectedSuccessIfNonJs(String message, [dynamic res]) {
  if (!Squadron.platformType.isJs) {
    throw unexpectedSuccess(
        'Unexpected success on ${Squadron.platformType.label}: $message', res);
  }
}

void _unexpectedFailureIfJs(String message, [dynamic ex]) {
  if (Squadron.platformType.isJs) {
    throw unexpectedFailure(
        'Unexpected failure on ${Squadron.platformType.label}: $message', ex);
  }
}

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.run(() {
    tc.group('- Lazy lists', () {
      testLazyLists(tc);
    });

    tc.group('- Lazy maps', () {
      testLazyMaps(tc);
    });

    tc.group('- Converters', () {
      tc.test('- custom identity is not considered an identity', () {
        expect(Converter.isIdentity<int>(_asInt), isFalse);
      });

      tc.test('- Type checks per platform', () async {
        // making sure those assumptions hold over time
        expect(1.1, isNotA<int>());
        expect(1.1, isA<double>());
        expect(1.toDouble(), isA<double>());
        if (Squadron.platformType.isJs) {
          expect(1.toDouble(), isA<int>());
          expect(1.toDouble() as int, 1);
        } else {
          expect(1.toDouble(), isNotA<int>());
          await expectLater(() => 1.toDouble() as int, _throwsTypeError);
        }
      });

      testCastConverter(tc);
      testNumConverter(tc);

      testInPlaceCastConverter(tc);
      testInPlaceNumConverter(tc);

      testLazyInPlaceCastConverter(tc);
      testLazyInPlaceNumConverter(tc);
    });

    tc.group('- Squadron converter', () {
      final platformConverter = Squadron.converter;

      tc.test('- Set', () {
        final converter = LazyInPlaceConverter(platformConverter);

        var success = false, called = 0;

        void check() {
          called++;
          success = (Squadron.converter == converter);
        }

        final key = Squadron.onConverterChanged(check);
        try {
          expect(success, isFalse);

          // update
          Squadron.converter = converter;
          expect(success, isTrue);
          expect(called, 1);
          expect(Squadron.converter, converter);

          // no change
          Squadron.converter = converter;
          expect(success, isTrue);
          expect(called, 1);
          expect(Squadron.converter, converter);

          // restore
          Squadron.converter = platformConverter;
          expect(success, isFalse);
          expect(called, 2);
          expect(Squadron.converter, platformConverter);

          // update again
          Squadron.converter = InPlaceConverter(platformConverter);
          expect(success, isFalse);
          expect(called, 3);
          expect(Squadron.converter, isNot(converter));
          expect(Squadron.converter, isNot(platformConverter));

          // reset
          success = true;
          Squadron.unregisterConverterChanged(key);
          Squadron.converter = null;
          expect(success, isTrue);
          expect(called, 3);
          expect(Squadron.converter, platformConverter);
        } finally {
          Squadron.unregisterConverterChanged(key);
          Squadron.converter = platformConverter;
        }
      });
    });
  });
}
