// ignore_for_file: file_names

part of '03_converter_suite.dart';

void testIdentityAwareBinaryConverter(TestContext tc) {
  tc.group('- IdentityAwareBinaryConverter', () {
    final converter = IdentityAwareBinaryConverter();

    tc.test('- Primitives', () {
      expect(converter.deserialize(converter.serialize(null)), isNull);
      expect(converter.deserialize(converter.serialize(true)), isTrue);
      expect(converter.deserialize(converter.serialize(false)), isFalse);
      expect(converter.deserialize(converter.serialize(42)), equals(42));
      expect(converter.deserialize(converter.serialize(-42)), equals(-42));
      expect(
          converter.deserialize(converter.serialize(3.14159)), equals(3.14159));
      expect(converter.deserialize(converter.serialize('hello squadron')),
          equals('hello squadron'));
    });

    tc.test('- Collections: List, Map, Set', () {
      final list = [1, 2, 3];
      final decodedList =
          converter.deserialize(converter.serialize(list)) as List;
      expect(decodedList, equals([1, 2, 3]));

      final map = {'a': 1, 'b': 2};
      final decodedMap = converter.deserialize(converter.serialize(map)) as Map;
      expect(decodedMap, equals({'a': 1, 'b': 2}));

      final set = {10, 20, 30};
      final decodedSet = converter.deserialize(converter.serialize(set)) as Set;
      expect(decodedSet, equals({10, 20, 30}));
    });

    tc.test('- Identity preservation (shared instances)', () {
      final innerList = [99, 100];
      final outerList = [innerList, innerList];

      final decoded =
          converter.deserialize(converter.serialize(outerList)) as List;
      expect(decoded.length, equals(2));
      expect(decoded[0], equals([99, 100]));
      expect(decoded[1], equals([99, 100]));
      expect(identical(decoded[0], decoded[1]), isTrue);
    });

    tc.test('- Cyclic graph handling', () {
      final List<dynamic> cyclicList = [];
      cyclicList.add(cyclicList);

      final decoded =
          converter.deserialize(converter.serialize(cyclicList)) as List;
      expect(decoded.length, equals(1));
      expect(identical(decoded[0], decoded), isTrue);
    });

    tc.test('- TypedData collections', () {
      final u8 = Uint8List.fromList([1, 2, 255]);
      final decodedU8 = converter.deserialize(converter.serialize(u8));
      expect(decodedU8, isA<Uint8List>());
      expect(decodedU8, equals(u8));

      final i8 = Int8List.fromList([-128, 0, 127]);
      final decodedI8 = converter.deserialize(converter.serialize(i8));
      expect(decodedI8, isA<Int8List>());
      expect(decodedI8, equals(i8));

      final u8c = Uint8ClampedList.fromList([0, 128, 255]);
      final decodedU8c = converter.deserialize(converter.serialize(u8c));
      expect(decodedU8c, isA<Uint8ClampedList>());
      expect(decodedU8c, equals(u8c));

      final i16 = Int16List.fromList([-32768, 0, 32767]);
      final decodedI16 = converter.deserialize(converter.serialize(i16));
      expect(decodedI16, isA<Int16List>());
      expect(decodedI16, equals(i16));

      final u16 = Uint16List.fromList([0, 32768, 65535]);
      final decodedU16 = converter.deserialize(converter.serialize(u16));
      expect(decodedU16, isA<Uint16List>());
      expect(decodedU16, equals(u16));

      final i32 = Int32List.fromList([-2147483648, 0, 2147483647]);
      final decodedI32 = converter.deserialize(converter.serialize(i32));
      expect(decodedI32, isA<Int32List>());
      expect(decodedI32, equals(i32));

      final u32 = Uint32List.fromList([0, 2147483648, 4294967295]);
      final decodedU32 = converter.deserialize(converter.serialize(u32));
      expect(decodedU32, isA<Uint32List>());
      expect(decodedU32, equals(u32));

      final f32 = Float32List.fromList([-1.5, 0.0, 3.14159]);
      final decodedF32 =
          converter.deserialize(converter.serialize(f32)) as Float32List;
      expect(decodedF32, isA<Float32List>());
      expect(decodedF32.length, equals(f32.length));
      for (int i = 0; i < f32.length; i++) {
        expect(decodedF32[i], closeTo(f32[i], 1e-5));
      }

      final f64 = Float64List.fromList([-1.5, 0.0, 3.141592653589793]);
      final decodedF64 = converter.deserialize(converter.serialize(f64));
      expect(decodedF64, isA<Float64List>());
      expect(decodedF64, equals(f64));

      final bd = ByteData(8)..setFloat64(0, 2.71828, Endian.little);
      final decodedBd =
          converter.deserialize(converter.serialize(bd)) as ByteData;
      expect(decodedBd, isA<ByteData>());
      expect(decodedBd.getFloat64(0, Endian.little), equals(2.71828));
    });

    tc.test('- TypedData collections (64-bit ints)', () {
      final i64 = Int64List.fromList([-9007199254740991, 0, 9007199254740991]);
      final decodedI64 = converter.deserialize(converter.serialize(i64));
      expect(decodedI64, isA<Int64List>());
      expect(decodedI64, equals(i64));

      final u64 = Uint64List.fromList([0, 9007199254740991]);
      final decodedU64 = converter.deserialize(converter.serialize(u64));
      expect(decodedU64, isA<Uint64List>());
      expect(decodedU64, equals(u64));
    }, skip: tc.runnerPlatform.isJs || tc.workerPlatform.isJs);

    tc.test('- TypedData identity preservation', () {
      final sharedBuffer = Uint8List.fromList([10, 20, 30]);
      final listWithShared = [sharedBuffer, sharedBuffer];

      final decoded =
          converter.deserialize(converter.serialize(listWithShared)) as List;
      expect(decoded.length, equals(2));
      expect(decoded[0], isA<Uint8List>());
      expect(decoded[1], isA<Uint8List>());
      expect(identical(decoded[0], decoded[1]), isTrue);
    });

    tc.test('- Reject corrupt ULEB128 (infinite 0x80)', () {
      final corruptData = Uint8List.fromList([0x04, ...List.filled(11, 0x80)]);
      expect(() => converter.deserialize(corruptData),
          throwsA(isA<FormatException>()));
    });
  });
}
