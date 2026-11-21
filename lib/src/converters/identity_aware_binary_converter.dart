import 'dart:convert';
import 'dart:typed_data';

import '../squadron_singleton.dart';
import 'serialization_context.dart';

class IdentityAwareBinaryConverter {
  IdentityAwareBinaryConverter()
      : _context = SerializationContext(Squadron.identical);

  final SerializationContext _context;

  void clearContext() => _context.clearContext();

  // ULEB128 encode
  static void _writeUleb128(BytesBuilder builder, int value) {
    while (true) {
      int byte = value & 0x7F;
      value >>= 7;
      if (value == 0) {
        builder.addByte(byte);
        break;
      } else {
        builder.addByte(byte | 0x80);
      }
    }
  }

  // ULEB128 decode
  static int _readUleb128(Uint8List bytes, _ReaderOffset offset) {
    int result = 0;
    int shift = 0;
    while (true) {
      if (offset.value >= bytes.length) {
        throw FormatException(
            'Unexpected end of binary data while reading ULEB128');
      }
      int byte = bytes[offset.value++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) {
        break;
      }
      shift += 7;
    }
    return result;
  }

  // ZigZag encoding for signed integers
  static int _encodeZigZag(int value) =>
      (value >= 0) ? (value * 2) : (-value * 2) - 1;
  static int _decodeZigZag(int value) =>
      ((value & 1) == 0) ? (value ~/ 2) : -((value + 1) ~/ 2);

  Uint8List serialize(dynamic value) {
    _context.clearContext();
    final builder = BytesBuilder();
    final collectionIndexMap = <Object, int>{};

    bool writeRef(Object val) {
      final existingIndex = collectionIndexMap[val];
      if (existingIndex != null) {
        builder.addByte(Tags.$ref);
        _writeUleb128(builder, existingIndex);
        return true;
      } else {
        collectionIndexMap[val] = collectionIndexMap.length;
        return false;
      }
    }

    void writeValue(dynamic val) {
      switch (val) {
        case null:
          builder.addByte(Tags.$null);

        case bool():
          builder.addByte(val ? Tags.$true : Tags.$false);

        case int():
          builder.addByte(Tags.$int);
          _writeUleb128(builder, _encodeZigZag(val));

        case double():
          builder.addByte(Tags.$double);
          final bd = ByteData(8);
          bd.setFloat64(0, val, Endian.little);
          builder.add(bd.buffer.asUint8List());

        case String():
          builder.addByte(Tags.$string);
          final utf8Bytes = utf8.encode(val);
          _writeUleb128(builder, utf8Bytes.length);
          builder.add(utf8Bytes);

        case TypedData():
          if (!writeRef(val)) {
            builder.addByte(Tags.$typedData);
            final kind = _getTypedDataKind(val);
            builder.addByte(kind.code);
            _writeUleb128(builder, val.lengthInBytes);
            builder.add(
                val.buffer.asUint8List(val.offsetInBytes, val.lengthInBytes));
          }

        case Iterable() || Map():
          if (!writeRef(val)) {
            if (val is Map) {
              builder.addByte(Tags.$map);
              _writeUleb128(builder, val.length);
              for (var entry in val.entries) {
                writeValue(entry.key);
                writeValue(entry.value);
              }
            } else {
              val as Iterable;
              builder.addByte((val is Set) ? Tags.$set : Tags.$list);
              _writeUleb128(builder, val.length);
              for (var item in val) {
                writeValue(item);
              }
            }
          }

        default:
          throw ArgumentError(
              'Unsupported type for binary serialization: ${val.runtimeType}');
      }
    }

    writeValue(value);
    return builder.toBytes();
  }

  dynamic deserialize(Uint8List bytes) {
    final offset = _ReaderOffset(0);
    final decodedCollections = <Object>[];

    dynamic readValue() {
      if (offset.value >= bytes.length) {
        throw FormatException('Unexpected end of binary data');
      }
      final tag = bytes[offset.value++];
      switch (tag) {
        case Tags.$null:
          return null;
        case Tags.$true:
          return true;
        case Tags.$false:
          return false;
        case Tags.$int:
          return _decodeZigZag(_readUleb128(bytes, offset));
        case Tags.$double:
          if (offset.value + 8 > bytes.length) {
            throw FormatException('Unexpected end of binary data for double');
          }
          final bd =
              ByteData.sublistView(bytes, offset.value, offset.value + 8);
          offset.value += 8;
          return bd.getFloat64(0, Endian.little);
        case Tags.$string:
          final length = _readUleb128(bytes, offset);
          if (offset.value + length > bytes.length) {
            throw FormatException('Unexpected end of binary data for string');
          }
          final strBytes = bytes.sublist(offset.value, offset.value + length);
          offset.value += length;
          return utf8.decode(strBytes);
        case Tags.$typedData:
          final kindCode = bytes[offset.value++];
          final lengthInBytes = _readUleb128(bytes, offset);
          if (offset.value + lengthInBytes > bytes.length) {
            throw FormatException(
                'Unexpected end of binary data for TypedData');
          }
          final rawBytes =
              bytes.sublist(offset.value, offset.value + lengthInBytes);
          offset.value += lengthInBytes;

          final typedData = _createTypedData(kindCode, rawBytes);
          decodedCollections.add(typedData);
          return typedData;
        case Tags.$map:
          final length = _readUleb128(bytes, offset);
          final map = <dynamic, dynamic>{};
          decodedCollections.add(map);
          for (int i = 0; i < length; i++) {
            final key = readValue();
            final val = readValue();
            map[key] = val;
          }
          return map;
        case Tags.$set:
          final length = _readUleb128(bytes, offset);
          final set = <dynamic>{};
          decodedCollections.add(set);
          for (int i = 0; i < length; i++) {
            set.add(readValue());
          }
          return set;
        case Tags.$list:
          final length = _readUleb128(bytes, offset);
          final list = <dynamic>[];
          decodedCollections.add(list);
          for (int i = 0; i < length; i++) {
            list.add(readValue());
          }
          return list;
        case Tags.$ref:
          final refIndex = _readUleb128(bytes, offset);
          if (refIndex >= decodedCollections.length) {
            throw FormatException(
                'Invalid collection reference index: $refIndex');
          }
          return decodedCollections[refIndex];
        default:
          throw FormatException(
              'Unknown binary type tag: 0x${tag.toRadixString(16)}');
      }
    }

    return readValue();
  }
}

class _ReaderOffset {
  _ReaderOffset(this.value);
  int value;
}

sealed class Tags {
  static const $null = 0x01;
  static const $true = 0x02;
  static const $false = 0x03;
  static const $int = 0x04;
  static const $double = 0x05;
  static const $string = 0x06;
  static const $map = 0x07;
  static const $set = 0x08;
  static const $list = 0x09;
  static const $typedData = 0x0A;
  static const $ref = 0xFF;
}

enum TypedDataKind {
  uint8(0x01),
  int8(0x02),
  uint8Clamped(0x03),
  int16(0x04),
  uint16(0x05),
  int32(0x06),
  uint32(0x07),
  int64(0x08),
  uint64(0x09),
  float32(0x0A),
  float64(0x0B),
  byteData(0x0C);

  const TypedDataKind(this.code);
  final int code;
}

TypedDataKind _getTypedDataKind(TypedData val) {
  switch (val) {
    case Int8List():
      return TypedDataKind.int8;
    case Uint8ClampedList():
      return TypedDataKind.uint8Clamped;
    case Uint8List():
      return TypedDataKind.uint8;
    case Int16List():
      return TypedDataKind.int16;
    case Uint16List():
      return TypedDataKind.uint16;
    case Int32List():
      return TypedDataKind.int32;
    case Uint32List():
      return TypedDataKind.uint32;
    case Int64List():
      return TypedDataKind.int64;
    case Uint64List():
      return TypedDataKind.uint64;
    case Float32List():
      return TypedDataKind.float32;
    case Float64List():
      return TypedDataKind.float64;
    case ByteData():
      return TypedDataKind.byteData;
    default:
      throw UnsupportedError('Unsupported typed data: ${val.runtimeType}');
  }
}

TypedData _createTypedData(int kindCode, Uint8List rawBytes) {
  switch (kindCode) {
    case 0x01:
      return rawBytes;
    case 0x02:
      return Int8List.sublistView(rawBytes);
    case 0x03:
      return Uint8ClampedList.sublistView(rawBytes);
    case 0x04:
      return Int16List.sublistView(rawBytes);
    case 0x05:
      return Uint16List.sublistView(rawBytes);
    case 0x06:
      return Int32List.sublistView(rawBytes);
    case 0x07:
      return Uint32List.sublistView(rawBytes);
    case 0x08:
      return Int64List.sublistView(rawBytes);
    case 0x09:
      return Uint64List.sublistView(rawBytes);
    case 0x0A:
      return Float32List.sublistView(rawBytes);
    case 0x0B:
      return Float64List.sublistView(rawBytes);
    case 0x0C:
      return ByteData.sublistView(rawBytes);
    default:
      throw FormatException(
          'Unknown TypedData kind code: 0x${kindCode.toRadixString(16)}');
  }
}
