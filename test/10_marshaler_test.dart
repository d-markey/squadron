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

  final france = Country(1, 'France');
  final belgium = Country(2, 'Belgium');

  final cityAFr = City('12345', 'fr-12345', france);
  final cityABe = City('12345', 'be-12345', belgium);
  final cityBFr = City('67890', 'fr-67890', france);

  DateTime dob() =>
      DateTime.now().subtract(Duration(days: (1 + Random().nextInt(60)) * 365));

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

      tc.group('- CONTEXT AWARENESS', () {
        tc.test('- Aware', () {
          final context1 = MarshalingContext();
          expect(context1.isContextAware, isTrue);
          final marshal = context1.converter.list<Object>(
              (x) => const PersonMarshaler().marshal(x, context1));

          final context2 = MarshalingContext();
          expect(context2.isContextAware, isTrue);
          final unmarshal = context2.converter.list<Person>(
              (x) => const PersonMarshaler().unmarshal(x, context2));

          final a = Person('X', 'y', dob(), cityAFr, null, null);
          final l = [a, a];
          final r = unmarshal(marshal(l));

          expect(identical(r, l), isFalse);
          expect(identical(r[0], r[1]), isTrue);
        });

        tc.test('- Unaware', () {
          final context1 = MarshalingContext(contextAware: false);
          expect(context1.isContextAware, isFalse);
          final marshal = context1.converter.list<Object>(
              (x) => const PersonMarshaler().marshal(x, context1));

          final context2 = MarshalingContext(contextAware: false);
          expect(context2.isContextAware, isFalse);
          final unmarshal = context2.converter.list<Person>(
              (x) => const PersonMarshaler().unmarshal(x, context2));

          final a = Person('X', 'y', dob(), cityAFr, null, null);
          final l = [a, a];
          final r = unmarshal(marshal(l));

          expect(r, isA<List<Person>>());
          expect(identical(r, l), isFalse);
          expect(identical(r[0], r[1]), isFalse);
        });
      });

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
    });
  });
}
