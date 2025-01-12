// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'fraction.dart';
import 'src/test_context.dart';
import 'src/utils.dart';
import 'worker_services/test_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '09_marshaler_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- MARSHALING', () {
      Future<Fraction> testSum(TestWorker testWorker,
          {required bool marshalIn, required bool marshalOut}) async {
        final res = await testWorker.fractionAdd(
          Fraction(1, 2),
          Fraction(1, 6),
          marshalIn: marshalIn,
          marshalOut: marshalOut,
        );
        expect(res, Fraction(2, 3));
        return res;
      }

      tc.test('- Unmarshaled "non-native" types work in VM, fail on Web',
          () async {
        await TestWorker(tc).useAsync((w) async {
          try {
            final sum = await testSum(w, marshalIn: false, marshalOut: false);
            if (tc.workerPlatform.isWeb) {
              throw unexpectedSuccess(
                  'unmarshalled call to fractionAdd()', sum);
            }
          } on SquadronException catch (ex) {
            if (tc.workerPlatform.isVm) rethrow;
            expect(
              ex,
              anyOf(
                reports('TypeError'), // JavaScript
                reports('not a subtype'), // Web Assembly
                reports('Failed to post request'), // Web Assembly
              ),
            );
          }
        });
      });

      tc.test('- Unmarshaled "non-native" input types work in VM, fail on Web',
          () async {
        await TestWorker(tc).useAsync((w) async {
          try {
            final sum = await testSum(w, marshalIn: false, marshalOut: true);
            if (tc.workerPlatform.isWeb) {
              throw unexpectedSuccess(
                  'unmarshalled call to fractionAdd()', sum);
            }
          } on SquadronException catch (ex) {
            if (tc.workerPlatform.isVm) rethrow;
            expect(
              ex,
              anyOf(
                reports('TypeError'), // JavaScript
                reports('not a subtype'), // Web Assembly
                reports('Failed to post request'), // Web Assembly
              ),
            );
          }
        });
      });

      tc.test('- Unmarshaled "non-native" output types work in VM, fail on Web',
          () async {
        await TestWorker(tc).useAsync((w) async {
          try {
            final sum = await testSum(w, marshalIn: true, marshalOut: false);
            if (tc.workerPlatform.isWeb) {
              throw unexpectedSuccess(
                  'unmarshalled call to fractionAdd()', sum);
            }
          } catch (ex) {
            if (tc.workerPlatform.isVm) rethrow;
            expect(
              ex,
              anyOf(
                reports('TypeError'), // JavaScript
                reports('not a subtype'), // Web Assembly
                reports('Failed to post response'), // Web Assembly
              ),
            );
          }
        });
      });

      tc.test('- Marshaled "non-native" types always work', () async {
        await TestWorker(tc).useAsync((w) async {
          testSum(w, marshalIn: true, marshalOut: true);
        });
      });

      tc.group('- TypedDataMarshaler', () {
        final rnd = math.Random();

        void rndFill(ByteBuffer b) {
          final bytes = b.asByteData();
          for (var i = 0; i < bytes.lengthInBytes; i++) {
            bytes.setUint8(i, rnd.nextInt(256));
          }
        }

        tc.test('- ByteData', () {
          final src = ByteData(16);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<ByteData>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(identical(res, src), isFalse);
          expect(res.lengthInBytes, src.lengthInBytes);
          for (var i = 0; i < src.lengthInBytes; i++) {
            expect(res.getUint8(i), src.getUint8(i));
          }
        });

        tc.test('- Uint8List', () {
          final src = Uint8List(16);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Uint8List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(res, src);
        });

        tc.test('- Int8List', () {
          final src = Int8List(16);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Int8List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(res, src);
        });

        tc.test('- Uint8ClampedList', () {
          final src = Uint8ClampedList(16);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Uint8ClampedList>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(res, src);
        });

        tc.test('- Uint16List', () {
          final src = Uint16List(16);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Uint16List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(res, src);
        });

        tc.test('- Int16List', () {
          final src = Int16List(16);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Int16List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(res, src);
        });

        tc.test('- Uint32List', () {
          final src = Uint32List(16);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Uint32List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(res, src);
        });

        tc.test('- Int32List', () {
          final src = Int32List(16);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Int32List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(res, src);
        });

        tc.test('- Int32x4List', () {
          final src = Int32x4List(4);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Int32x4List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(identical(res, src), isFalse);
          expect(res.lengthInBytes, src.lengthInBytes);
          for (var i = 0; i < src.length; i++) {
            final s = src[i], r = res[i];
            expect(s.w, r.w);
            expect(s.x, r.x);
            expect(s.y, r.y);
            expect(s.z, r.z);
          }
        });

        tc.test('- Uint64List', () {
          final src = Uint64List(4);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Uint64List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(res, src);
        }, skip: tc.runnerPlatform.isJs);

        tc.test('- Int64List', () {
          final src = Int64List(4);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Int64List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(res, src);
        }, skip: tc.runnerPlatform.isJs);

        void $dblExpect(double res, double src) {
          if (src.isNaN) {
            expect(res, isNaN);
          } else {
            expect(res, src);
          }
        }

        tc.test('- Float32List', () {
          final src = Float32List(4);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Float32List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(identical(res, src), isFalse);
          expect(res.length, src.length);
          for (var i = 0; i < src.length; i++) {
            $dblExpect(res[i], src[i]);
          }
        });

        tc.test('- Float64List', () {
          final src = Float64List(4);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Float64List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(identical(res, src), isFalse);
          expect(res.length, src.length);
          for (var i = 0; i < src.length; i++) {
            $dblExpect(res[i], src[i]);
          }
        });

        tc.test('- Float32x4List', () {
          final src = Float32x4List(4);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Float32x4List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(identical(res, src), isFalse);
          expect(res.lengthInBytes, src.lengthInBytes);
          for (var i = 0; i < src.length; i++) {
            final s = src[i], r = res[i];
            $dblExpect(s.w, r.w);
            $dblExpect(s.x, r.x);
            $dblExpect(s.y, r.y);
            $dblExpect(s.z, r.z);
          }
        });

        tc.test('- Float64x2List', () {
          final src = Float64x2List(4);
          rndFill(src.buffer);
          final marshaler = TypedDataMarshaler<Float64x2List>();
          final res = marshaler.unmarshal(marshaler.marshal(src));
          expect(identical(res, src), isFalse);
          expect(res.lengthInBytes, src.lengthInBytes);
          for (var i = 0; i < src.length; i++) {
            final s = src[i], r = res[i];
            $dblExpect(s.x, r.x);
            $dblExpect(s.y, r.y);
          }
        });
      });
    });
  });
}
