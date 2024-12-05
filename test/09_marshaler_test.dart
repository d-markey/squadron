// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/test_service_worker.dart';

void main() {
  TestContext.init('~').then(execute);
  TestContext.init('~', SquadronPlatformType.wasm).then(execute);
}

String testScript = '09_marshaler_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.run(() {
    tc.group("- Marshaler", () {
      late TestWorker testWorker;

      setUpAll(() async {
        testWorker = TestWorker(tc);
        await testWorker.start();
      });

      tearDownAll(() {
        testWorker.stop();
      });

      Future<BigInt> testSum(
              {required bool marshalIn, required bool marshalOut}) =>
          testWorker.bigIntAdd(BigInt.one, BigInt.two,
              marshalIn: marshalIn, marshalOut: marshalOut);

      tc.test('- unmarshaled "non-native" types work in VM, fail on Web',
          () async {
        try {
          final sum = await testSum(marshalIn: false, marshalOut: false);
          expect(sum, BigInt.from(3));
          if (tc.workerPlatform.isWeb) {
            throw unexpectedSuccess('unmarshalled call to bigIntAdd()', sum);
          }
        } on SquadronError catch (ex) {
          if (tc.workerPlatform.isVm) rethrow;
          expect(ex, reports('Failed to post request'));
        }
      });

      tc.test('- unmarshaled "non-native" input types work in VM, fail on Web',
          () async {
        try {
          final sum = await testSum(marshalIn: false, marshalOut: true);
          expect(sum, BigInt.from(3));
          if (tc.workerPlatform.isWeb) {
            throw unexpectedSuccess('unmarshalled call to bigIntAdd()', sum);
          }
        } on SquadronError catch (ex) {
          if (tc.workerPlatform.isVm) rethrow;
          expect(ex, reports('Failed to post request'));
        }
      });

      tc.test('- unmarshaled "non-native" output types work in VM, fail on Web',
          () async {
        try {
          final sum = await testSum(marshalIn: true, marshalOut: false);
          expect(sum, BigInt.from(3));
          if (tc.workerPlatform.isWeb) {
            throw unexpectedSuccess('unmarshalled call to bigIntAdd()', sum);
          }
        } on SquadronError catch (ex) {
          if (tc.workerPlatform.isVm) rethrow;
          expect(ex, reports('Failed to post response'));
        }
      });

      tc.test('- marshaled "non-native" types always work', () async {
        final sum = await testSum(marshalIn: true, marshalOut: true);
        expect(sum, BigInt.from(3));
      });
    });

    tc.group("- TypedDataMarshaler", () {
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
      }, skip: tc.clientPlatform.isJs);

      tc.test('- Int64List', () {
        final src = Int64List(4);
        rndFill(src.buffer);
        final marshaler = TypedDataMarshaler<Int64List>();
        final res = marshaler.unmarshal(marshaler.marshal(src));
        expect(res, src);
      }, skip: tc.clientPlatform.isJs);

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
}
