// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import '03_converter_test__list_features.dart';
import '03_converter_test__map_features.dart';
import 'src/test_context.dart';
import 'src/utils.dart';

part '03_converter_test_cast.dart';
part '03_converter_test_cast_in_place.dart';
part '03_converter_test_cast_lazy_in_place.dart';
part '03_converter_test_num.dart';
part '03_converter_test_num_in_place.dart';
part '03_converter_test_num_lazy_in_place.dart';

Future<void> main() => TestContext.run(
      execute,
      mixedContext: false /* this test suite has no workers */,
    );

const testScript = '03_converter_test.dart';

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

bool _isTypeError(Object ex) {
  if (ex is TypeError) return true;
  if (ex is WorkerException) {
    final msg = ex.message;
    return msg.contains('TypeError') || msg.contains('not a subtype');
  }
  return false;
}

final _throwsTypeError = anyOf(
    failsWith<TypeError>(),
    allOf(
      failsWith<WorkerException>(),
      anyOf(reports('TypeError'), reports('not a subtype')),
    ));
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

  tc.launch(() {
    tc.group('- LAZY COLLECTIONS', () {
      tc.group('- Lazy list', () {
        testLazyLists(tc);
      });

      tc.group('- Lazy map', () {
        testLazyMaps(tc);
      });
    });

    tc.group('- CONVERTERS', () {
      tc.test('- Type checks per platform', () async {
        // making sure those assumptions hold over time
        expect(1.1, isNotA<int>());
        expect(1.1, isA<double>());
        dynamic one = 1.0;
        expect(one, isA<double>());
        if (Squadron.platformType.isJs) {
          expect(one, isA<int>());
          expect(one as int, 1);
        } else {
          expect(one, isNotA<int>());
          await expectLater(() => one as int, _throwsTypeError);
        }
      });

      tc.test('- Custom identity is not considered an identity', () {
        expect(Converter.isIdentity<int>(_asInt), isFalse);
      });

      testCastConverter(tc);
      testInPlaceCastConverter(tc);
      testLazyInPlaceCastConverter(tc);

      testNumConverter(tc);
      testInPlaceNumConverter(tc);
      testLazyInPlaceNumConverter(tc);

      tc.test('- Change default converter', () {
        final defaultConverter = Squadron.converter;

        final converter = LazyInPlaceConverter(defaultConverter);

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
          Squadron.converter = defaultConverter;
          expect(success, isFalse);
          expect(called, 2);
          expect(Squadron.converter, defaultConverter);

          // update again
          Squadron.converter = InPlaceConverter(defaultConverter);
          expect(success, isFalse);
          expect(called, 3);
          expect(Squadron.converter, isNot(converter));
          expect(Squadron.converter, isNot(defaultConverter));

          // reset
          success = true;
          Squadron.unregisterConverterChanged(key);
          Squadron.converter = null;
          expect(success, isTrue);
          expect(called, 3);
          expect(Squadron.converter, defaultConverter);
        } finally {
          Squadron.unregisterConverterChanged(key);
          Squadron.converter = defaultConverter;
        }
      });
    });
  });
}
