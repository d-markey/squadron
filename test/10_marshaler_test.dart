// ignore_for_file: file_names

import 'dart:math';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'src/test_context.dart';
import 'src/utils.dart';
import 'worker_services/fraction.dart';
import 'worker_services/persons/city.dart';
import 'worker_services/persons/country.dart';
import 'worker_services/persons/person.dart';
import 'worker_services/persons/person_service_worker.dart';
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
          await testSum(w, marshalIn: true, marshalOut: true);
        });
      });

      final france = Country(1, 'France');
      final belgium = Country(2, 'Belgium');

      final cityAFr = City('12345', 'fr-12345', france);
      final cityABe = City('12345', 'be-12345', belgium);
      final cityBFr = City('67890', 'fr-67890', france);

      DateTime dob() => DateTime.now()
          .subtract(Duration(days: (1 + Random().nextInt(60)) * 365));

      final me = Person('ME', 'Myself', dob(), cityAFr, null, null);
      final p1 = Person('P', '1', dob(), cityAFr, null, null);
      final p2 = Person('P', '2', dob(), cityAFr, null, null);
      final p3 = Person('P', '3', dob(), cityABe, null, null);
      final c1 = Person('C', '1', dob(), cityAFr, p1, p2);
      final c2 = Person('C', '2', dob(), cityAFr, p2, p1);
      final c3 = Person('C', '3', dob(), cityBFr, p1, null);
      final c4 = Person('C', '4', dob(), cityBFr, null, p1);
      final c5 = Person('C', '5', dob(), cityABe, p3, null);

      final a = Person('A', 'a', dob(), cityAFr, null, null);
      final b = Person('B', 'b', dob(), cityAFr, null, null);
      final d = Person('D', 'd', dob(), cityABe, null, null);
      // a friend of b
      // b friend of a
      // d friend of b
      a.friends.add(b);
      b.friends.add(a);
      d.friends.add(b);

      tc.test('- Person - Self', () async {
        await PersonWorker(tc).useAsync((w) async {
          expect(await w.getKindType(me, me), 'self');
          expect(await w.getKindType(p1, p1), 'self');
        });
      });

      tc.test('- Person - Other', () async {
        await PersonWorker(tc).useAsync((w) async {
          expect(await w.getKindType(me, p1), 'other');
          expect(await w.getKindType(me, c1), 'other');
          expect(await w.getKindType(p1, p2), 'other');
        });
      });

      tc.test('- Person - Parent', () async {
        await PersonWorker(tc).useAsync((w) async {
          expect(await w.getKindType(p1, c1), 'parent');
          expect(await w.getKindType(p2, c1), 'parent');
          expect(await w.getKindType(p1, c2), 'parent');
          expect(await w.getKindType(p2, c2), 'parent');
          expect(await w.getKindType(p1, c3), 'parent');
          expect(await w.getKindType(p1, c4), 'parent');
          expect(await w.getKindType(p3, c5), 'parent');
        });
      });

      tc.test('- Person - Child', () async {
        await PersonWorker(tc).useAsync((w) async {
          expect(await w.getKindType(c1, p1), 'child');
          expect(await w.getKindType(c1, p2), 'child');
          expect(await w.getKindType(c2, p1), 'child');
          expect(await w.getKindType(c2, p2), 'child');
          expect(await w.getKindType(c3, p1), 'child');
          expect(await w.getKindType(c4, p1), 'child');
          expect(await w.getKindType(c5, p3), 'child');
        });
      });

      tc.test('- Person - Sibling', () async {
        await PersonWorker(tc).useAsync((w) async {
          expect(await w.getKindType(c1, c2), 'sibling');
          expect(await w.getKindType(c1, c3), 'sibling');
          expect(await w.getKindType(c1, c4), 'sibling');
          expect(await w.getKindType(c2, c1), 'sibling');
          expect(await w.getKindType(c2, c3), 'sibling');
          expect(await w.getKindType(c2, c4), 'sibling');
          expect(await w.getKindType(c3, c1), 'sibling');
          expect(await w.getKindType(c3, c2), 'sibling');
          expect(await w.getKindType(c3, c4), 'sibling');
          expect(await w.getKindType(c4, c1), 'sibling');
          expect(await w.getKindType(c4, c2), 'sibling');
          expect(await w.getKindType(c4, c3), 'sibling');
        });
      });

      tc.test('- Person - Friend', () async {
        await PersonWorker(tc).useAsync((w) async {
          expect(await w.getKindType(a, b), 'friend'); // cyclical!
          expect(await w.getKindType(b, d), 'friend');
          expect(await w.getKindType(b, a), 'friend'); // cyclical!
          expect(await w.getKindType(d, b), 'friend');
        });
      });

      tc.test('- Person - Friend of friend', () async {
        await PersonWorker(tc).useAsync((w) async {
          expect(await w.getKindType(a, d), 'friend-of-friend');
          expect(await w.getKindType(d, a), 'friend-of-friend');
        });
      });

      // tc.group('- TypedDataMarshaler', () {
      //   final rnd = math.Random();

      //   void rndFill(ByteBuffer b) {
      //     final bytes = b.asByteData();
      //     for (var i = 0; i < bytes.lengthInBytes; i++) {
      //       bytes.setUint8(i, rnd.nextInt(256));
      //     }
      //   }

      //   tc.test('- ByteData', () {
      //     final src = ByteData(16);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<ByteData>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(identical(res, src), isFalse);
      //     expect(res.lengthInBytes, src.lengthInBytes);
      //     for (var i = 0; i < src.lengthInBytes; i++) {
      //       expect(res.getUint8(i), src.getUint8(i));
      //     }
      //   });

      //   tc.test('- Uint8List', () {
      //     final src = Uint8List(16);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Uint8List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(res, src);
      //   });

      //   tc.test('- Int8List', () {
      //     final src = Int8List(16);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Int8List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(res, src);
      //   });

      //   tc.test('- Uint8ClampedList', () {
      //     final src = Uint8ClampedList(16);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Uint8ClampedList>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(res, src);
      //   });

      //   tc.test('- Uint16List', () {
      //     final src = Uint16List(16);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Uint16List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(res, src);
      //   });

      //   tc.test('- Int16List', () {
      //     final src = Int16List(16);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Int16List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(res, src);
      //   });

      //   tc.test('- Uint32List', () {
      //     final src = Uint32List(16);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Uint32List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(res, src);
      //   });

      //   tc.test('- Int32List', () {
      //     final src = Int32List(16);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Int32List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(res, src);
      //   });

      //   tc.test('- Int32x4List', () {
      //     final src = Int32x4List(4);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Int32x4List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(identical(res, src), isFalse);
      //     expect(res.lengthInBytes, src.lengthInBytes);
      //     for (var i = 0; i < src.length; i++) {
      //       final s = src[i], r = res[i];
      //       expect(s.w, r.w);
      //       expect(s.x, r.x);
      //       expect(s.y, r.y);
      //       expect(s.z, r.z);
      //     }
      //   });

      //   tc.test('- Uint64List', () {
      //     final src = Uint64List(4);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Uint64List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(res, src);
      //   }, skip: tc.runnerPlatform.isJs);

      //   tc.test('- Int64List', () {
      //     final src = Int64List(4);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Int64List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(res, src);
      //   }, skip: tc.runnerPlatform.isJs);

      //   void $dblExpect(double res, double src) {
      //     if (src.isNaN) {
      //       expect(res, isNaN);
      //     } else {
      //       expect(res, src);
      //     }
      //   }

      //   tc.test('- Float32List', () {
      //     final src = Float32List(4);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Float32List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(identical(res, src), isFalse);
      //     expect(res.length, src.length);
      //     for (var i = 0; i < src.length; i++) {
      //       $dblExpect(res[i], src[i]);
      //     }
      //   });

      //   tc.test('- Float64List', () {
      //     final src = Float64List(4);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Float64List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(identical(res, src), isFalse);
      //     expect(res.length, src.length);
      //     for (var i = 0; i < src.length; i++) {
      //       $dblExpect(res[i], src[i]);
      //     }
      //   });

      //   tc.test('- Float32x4List', () {
      //     final src = Float32x4List(4);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Float32x4List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(identical(res, src), isFalse);
      //     expect(res.lengthInBytes, src.lengthInBytes);
      //     for (var i = 0; i < src.length; i++) {
      //       final s = src[i], r = res[i];
      //       $dblExpect(s.w, r.w);
      //       $dblExpect(s.x, r.x);
      //       $dblExpect(s.y, r.y);
      //       $dblExpect(s.z, r.z);
      //     }
      //   });

      //   tc.test('- Float64x2List', () {
      //     final src = Float64x2List(4);
      //     rndFill(src.buffer);
      //     final marshaler = TypedDataMarshaler<Float64x2List>();
      //     final res = marshaler.unmarshal(marshaler.marshal(src));
      //     expect(identical(res, src), isFalse);
      //     expect(res.lengthInBytes, src.lengthInBytes);
      //     for (var i = 0; i < src.length; i++) {
      //       final s = src[i], r = res[i];
      //       $dblExpect(s.x, r.x);
      //       $dblExpect(s.y, r.y);
      //     }
      //   });
      // });
    });
  });
}
