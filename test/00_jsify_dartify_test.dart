// ignore_for_file: file_names

@TestOn('dart2js || dart2wasm')
library;

import 'dart:js_interop';
import 'dart:typed_data' as td;

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/web/_patch.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

import 'src/test_context.dart';

Future<void> main() => TestContext.run(
      execute,
      mixedContext: false /* this test suite has no workers */,
    );

const testScript = '00_jsify_dartify_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- PATCH', () {
      tc.group('- JS TYPES', () {
        tc.test('Date', () {
          final d = $JSDate.$fromUnixTimestamp(42);
          expect(d, isA<$JSDate>());
          expect(d.isA<$JSDate>(), isTrue);
          expect(d.$getTime(), equals(42));
        });

        tc.test('BigInt', () {
          final maxInt = 9007199254740991;
          final bigintFromStr = $JSBigInt('$maxInt$maxInt'.toJS);
          expect(bigintFromStr, isA<JSBigInt>());
          expect(bigintFromStr.isA<JSBigInt>(), isTrue);
          expect(bigintFromStr.toString(), '$maxInt$maxInt');
          final bigintFromInt = $JSBigInt(maxInt.toJS);
          expect(bigintFromInt, isA<JSBigInt>());
          expect(bigintFromInt.isA<JSBigInt>(), isTrue);
          expect(bigintFromInt.toString(), maxInt.toString());
        });
      });

      tc.group('- JSIFY', () {
        tc.test('- int', () {
          final t = <JSAny?>[].toJS;
          final x = $jsify(1, t);
          expect(x.isA<JSNumber>(), isTrue);
          expect(t.$length, 0);
        });

        tc.test('- double', () {
          final t = <JSAny?>[].toJS;
          final x = $jsify(1.1, t);
          expect(x.isA<JSNumber>(), isTrue);
          expect(t.$length, 0);
        });

        tc.test('- String', () {
          final t = <JSAny?>[].toJS;
          final x = $jsify('test', t);
          expect(x.isA<JSString>(), isTrue);
          expect(t.$length, 0);
        });

        tc.test('- BigInt', () {
          final t = <JSAny?>[].toJS;
          final x = $jsify(BigInt.two, t);
          expect(x.isA<JSBigInt>(), isTrue);
          expect((x as JSBigInt).toString(), '2');
          expect(t.$length, 0);
        });

        tc.test('- DateTime', () {
          final t = <JSAny?>[].toJS;
          final x = $jsify(DateTime.fromMillisecondsSinceEpoch(42), t);
          expect(x.isA<$JSDate>(), isTrue);
          expect((x as $JSDate).$getTime(), 42);
          expect(t.$length, 0);
        });

        tc.test('- List', () {
          final t = <JSAny?>[].toJS;
          final x = $jsify([1, 2, 3], t);
          expect(x.isA<JSArray>(), isTrue);
          expect(t.$length, 0);
        });

        tc.test('- Set', () {
          final t = <JSAny?>[].toJS;
          final x = $jsify({1, 2, 3}, t);
          expect(x.isA<$JSSet>(), isTrue);
          expect(t.$length, 0);
        });

        tc.test('- Map', () {
          final t = <JSAny?>[].toJS;
          final x = $jsify({'one': 1, 'two': 2, 'three': 3}, t);
          expect(x.isA<$JSMap>(), isTrue);
          expect(t.$length, 0);
        });

        tc.test('- Uint16List', () {
          final t = <JSAny?>[].toJS;
          final data = td.Uint16List.fromList([1, 2, 3]);
          final x = $jsify(data, t);
          expect(x, isNotNull);
          expect(t.$length, 1);
          expect(t.$at(0).isA<JSArrayBuffer>(), isTrue);
          expect((t.$at(0) as JSArrayBuffer).$byteLength, data.length * 16 / 8);
        });

        tc.test('- Port', () {
          final t = <JSAny?>[].toJS;
          final channel = MessageChannel();
          final x = $jsify(channel.port1, t);
          expect(x.isA<MessagePort>(), isTrue);
          expect(t.$length, 1);
          expect(t.$at(0).isA<MessagePort>(), isTrue);
        });

        tc.test('- Mixed list', () {
          final t = <JSAny?>[].toJS;
          final channel = MessageChannel();
          final data = td.Uint16List.fromList([1, 2, 3]);
          final x = $jsify([
            data,
            [1, 2, 3],
            channel.port1,
          ], t);
          expect(x.isA<JSArray>(), isTrue);
          x as JSArray;
          expect(x.$length, 3);
          expect(x.$at(0), isNotNull);
          expect(x.$at(1).isA<JSArray>(), isTrue);
          expect(x.$at(2).isA<MessagePort>(), isTrue);

          expect(t.$length, 2);
          expect(t.$at(0).isA<JSArrayBuffer>(), isTrue);
          expect((t.$at(0) as JSArrayBuffer).$byteLength, data.length * 16 / 8);
          expect(t.$at(1).isA<MessagePort>(), isTrue);
        });

        tc.test('- Acyclic reference', () {
          final t = <JSAny?>[].toJS;
          final channel = MessageChannel();
          final data = td.Uint16List.fromList([0, 1, 2, 3]);
          final x = $jsify([data, channel.port1, data, channel.port1], t);
          expect(x.isA<JSArray>(), isTrue);
          x as JSArray;
          expect(x.$length, 4);
          expect(x.$at(0), isNotNull);
          expect(x.$at(1).isA<MessagePort>(), isTrue);
          expect(x.$at(2), isNotNull);
          expect(x.$at(3).isA<MessagePort>(), isTrue);

          expect($is(x.$at(2), x.$at(0)), isTrue);
          expect($is(x.$at(3), x.$at(1)), isTrue);

          expect(t.$length, 2);
          expect(t.$at(0).isA<JSArrayBuffer>(), isTrue);
          expect((t.$at(0) as JSArrayBuffer).$byteLength, data.length * 16 / 8);
          expect(t.$at(1).isA<MessagePort>(), isTrue);
        });

        tc.test('- Cyclic reference', () {
          final t = <JSAny?>[].toJS;
          final channel = MessageChannel();
          final data = td.Uint16List.fromList([1, 2, 3]);
          final message = [data, channel.port1, data, channel.port1];
          message.add(message);
          final x = $jsify(message, t);
          expect(x.isA<JSArray>(), isTrue);
          x as JSArray;
          expect(x.$length, 5);
          expect(x.$at(0), isNotNull);
          expect(x.$at(1).isA<MessagePort>(), isTrue);
          expect(x.$at(2), isNotNull);
          expect(x.$at(3).isA<MessagePort>(), isTrue);
          expect(x.$at(4).isA<JSArray>(), isTrue);

          expect($is(x.$at(2), x.$at(0)), isTrue);
          expect($is(x.$at(3), x.$at(1)), isTrue);
          expect($is(x.$at(4), x), isTrue);

          expect(t.$length, 2);
          expect(t.$at(0).isA<JSArrayBuffer>(), isTrue);
          expect((t.$at(0) as JSArrayBuffer).$byteLength, data.length * 16 / 8);
          expect(t.$at(1).isA<MessagePort>(), isTrue);
        });
      });

      tc.group('- DARTIFY', () {
        tc.test('- int', () {
          final x = $dartify(1.toJS);
          expect(x, Squadron.platformType.isWasm ? isA<double>() : isA<int>());
          expect(x, 1);
        });

        tc.test('- double', () {
          final x = $dartify(1.1.toJS);
          expect(x, isA<double>());
          expect(x, 1.1);

          final y = $dartify(1.0.toJS);
          expect(y, isA<double>());
          expect(y, 1.0);
        });

        tc.test('- String', () {
          final x = $dartify('Test'.toJS);
          expect(x, isA<String>());
          expect(x, 'Test');
        });

        tc.test('- BigInt', () {
          var val = BigInt.parse('123456789');
          for (var i = 1; i < 8; i++) {
            val = val * val;
          }
          final x = $dartify($JSBigInt(val.toString().toJS));
          expect(x, isA<BigInt>());
          expect(x, val);
        });

        tc.test('- DateTime', () {
          final x = $dartify($JSDate.$fromUnixTimestamp(42));
          expect(x, isA<DateTime>());
          expect(x, DateTime.fromMillisecondsSinceEpoch(42));
        });

        tc.test('- List', () {
          final x = $dartify([1.toJS, 'Test'.toJS].toJS);
          expect(x, isA<List>());
          x as List;
          expect(x, hasLength(2));
          expect(x[0], 1);
          expect(x[1], 'Test');
        });

        tc.test('- Set', () {
          final s = $JSSet();
          s.$add(1.toJS);
          s.$add(1.toJS);
          s.$add('Test'.toJS);
          s.$add('Test'.toJS);
          final x = $dartify(s);
          expect(x, isA<Set>());
          expect(x, hasLength(2));
          expect(x, contains(1));
          expect(x, contains('Test'));
        });

        tc.test('- Map', () {
          final m = $JSMap();
          m.$set(1.toJS, 2.toJS);
          m.$set('Test'.toJS, 4.toJS);
          final x = $dartify(m);
          expect(x, isA<Map>());
          x as Map;
          expect(x, hasLength(2));
          expect(x[1], 2);
          expect(x['Test'], 4);
        });

        tc.test('- Uint16List', () {
          final t = td.Uint16List.fromList([1, 2, 3]).toJS;
          final x = $dartify(t);
          expect(x, isA<td.Uint16List>());
          x as td.Uint16List;
          expect(x.length, 3);
        });

        tc.test('- Port', () {
          final channel = MessageChannel();
          final x = $dartify(channel.port1);
          expect(x, isA<MessagePort>());
        });

        tc.test('- Mixed list', () {
          final channel = MessageChannel();
          final x = $dartify([
            td.Uint16List.fromList([1, 2, 3]).toJS,
            [1.toJS, 2.toJS, 3.toJS].toJS,
            channel.port1,
          ].toJS);
          expect(x, isA<List>());
          x as List;
          expect(x[0], isA<td.Uint16List>());
          expect(x[1], isA<List>());
          expect(x[2], isA<MessagePort>());
        });

        tc.test('- Acyclic reference', () {
          final channel = MessageChannel();
          final data = td.Uint16List.fromList([1, 2, 3]).toJS;
          final x = $dartify([data, channel.port1, data, channel.port1].toJS);
          expect(x, isA<List>());
          x as List;
          expect(x[0], isA<td.Uint16List>());
          expect(x[1], isA<MessagePort>());
          expect(x[2], isA<td.Uint16List>());
          expect(x[3], isA<MessagePort>());

          expect(identical(x[0], x[2]), isTrue);
          expect(identical(x[1], x[3]), isTrue);
        });

        tc.test('- Cyclic reference', () {
          final channel = MessageChannel();
          final data = td.Uint16List.fromList([1, 2, 3]).toJS;
          final l = [data, channel.port1, data, channel.port1].toJS;
          l.$push(l);
          final x = $dartify(l);
          expect(x, isA<List>());
          x as List;
          expect(x[0], isA<td.Uint16List>());
          expect(x[1], isA<MessagePort>());
          expect(x[2], isA<td.Uint16List>());
          expect(x[3], isA<MessagePort>());
          expect(x[4], isA<List>());

          expect(identical(x[0], x[2]), isTrue);
          expect(identical(x[1], x[3]), isTrue);
          expect(identical(x[4], x), isTrue);
        });
      });

      tc.group('- TRANSFERIFY', () {
        tc.test('- Base types don\'t need transfer', () {
          final t = JSArray();
          $transferify(1.toJS, t);
          $transferify(1.2.toJS, t);
          $transferify('Test'.toJS, t);
          $transferify(true.toJS, t);
          $transferify($JSBigInt('2'.toJS), t);
          $transferify($JSDate.$fromUnixTimestamp(100), t);

          final array = JSArray();
          array.$push(0.toJS);
          array.$push(1.toJS);
          $transferify(array, t);

          final map = $JSMap();
          map.$set('zero'.toJS, 0.toJS);
          map.$set('one'.toJS, 1.toJS);
          $transferify(map, t);

          expect(t.$length, isZero);
        });

        tc.test('- JSArrayBuffer - same instance', () {
          final t = JSArray();

          final u32 = td.Uint32List(4).toJS;
          $transferify([u32, u32].toJS, t);

          expect(t.$length, 1);
          expect(t.$at(0).isA<JSArrayBuffer>(), isTrue);
          expect((t.$at(0) as JSArrayBuffer).$byteLength, 4 * 32 / 8);
        });

        tc.test('- JSArrayBuffer - different instances', () {
          final t = JSArray();

          final u8 = td.Uint8List(4).toJS;
          final u32 = td.Uint32List(4).toJS;
          $transferify([u8, u32].toJS, t);

          expect(t.$length, 2);
          expect(t.$at(0).isA<JSArrayBuffer>(), isTrue);
          expect((t.$at(0) as JSArrayBuffer).$byteLength, 4 * 8 / 8);
          expect(t.$at(1).isA<JSArrayBuffer>(), isTrue);
          expect((t.$at(1) as JSArrayBuffer).$byteLength, 4 * 32 / 8);
        });

        tc.test('- JSArrayBuffer - same buffer', () {
          final t = JSArray();

          final buffer = td.ByteData(4 * 32 ~/ 8).buffer;
          final u8 = buffer.asUint8List().toJS;
          final u32 = buffer.asUint32List().toJS;
          $transferify([u8, u32].toJS, t);

          if (Squadron.platformType.isWasm) {
            // seems like the underlying buffer is different in Wasm
            expect(t.$length, 2);
            expect(t.$at(0).isA<JSArrayBuffer>(), isTrue);
            expect(
                (t.$at(0) as JSArrayBuffer).$byteLength, buffer.lengthInBytes);
            expect(t.$at(1).isA<JSArrayBuffer>(), isTrue);
            expect(
                (t.$at(1) as JSArrayBuffer).$byteLength, buffer.lengthInBytes);
            expect($is(t.$at(0), t.$at(1)), isFalse);

            // expect($is(buffer.toJS, buffer.toJS), isTrue,
            //     reason: 'JSified buffer is the same');
            // expect($is(t.$at(0), buffer.toJS), isTrue,
            //     reason: 'First buffer is the underlying buffer');
            // expect($is(t.$at(1), buffer.toJS), isTrue,
            //     reason: 'Second buffer is the underlying buffer');
          } else {
            expect(t.$length, 1);
            expect(t.$at(0).isA<JSArrayBuffer>(), isTrue);
            expect(
                (t.$at(0) as JSArrayBuffer).$byteLength, buffer.lengthInBytes);
            expect($is(t.$at(0), buffer.toJS), isTrue);
          }
        });

        tc.test('- MessagePort - same instance', () {
          final t = JSArray();

          final channel1 = MessageChannel();
          $transferify([channel1.port1, channel1.port1].toJS, t);

          expect(t.$length, 1);
          expect(t.$at(0).isA<MessagePort>(), isTrue);
        });

        tc.test('- MessagePort - different instances', () {
          final t = JSArray();

          final channel1 = MessageChannel();
          final channel2 = MessageChannel();
          $transferify([channel1.port1, channel2.port1].toJS, t);

          expect(t.$length, 2);
          expect(t.$at(0).isA<MessagePort>(), isTrue);
          expect(t.$at(1).isA<MessagePort>(), isTrue);

          expect($is(t.$at(0), t.$at(1)), isFalse);
        });
      });
    });
  });
}
