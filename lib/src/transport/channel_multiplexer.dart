import 'dart:async';
import 'dart:typed_data';

import '../converters/identity_aware_binary_converter.dart';
import 'stream_transport.dart';

enum MessageType {
  request(0x00),
  response(0x01),
  streamItem(0x02),
  controlSignal(0x03);

  const MessageType(this.value);
  final int value;

  static MessageType fromValue(int val) =>
      values.firstWhere((t) => t.value == val,
          orElse: () => throw FormatException(
              'Unknown message type: 0x${val.toRadixString(16)}'));
}

enum ControlSignal {
  endOfStream(0x01),
  cancellation(0x02),
  error(0x03),
  log(0x04);

  const ControlSignal(this.value);
  final int value;

  static ControlSignal fromValue(int val) =>
      values.firstWhere((t) => t.value == val,
          orElse: () => throw FormatException(
              'Unknown control signal: 0x${val.toRadixString(16)}'));
}

class MultiplexedMessage {
  MultiplexedMessage({
    required this.channelId,
    required this.type,
    this.controlSignal,
    required this.payload,
  });

  final int channelId;
  final MessageType type;
  final ControlSignal? controlSignal;
  final dynamic payload;
}

class ChannelMultiplexer {
  ChannelMultiplexer(this._transport) {
    _subscription = _transport.messages.listen(_handleIncomingMessage);
  }

  final StreamTransport _transport;
  final IdentityAwareBinaryConverter _converter =
      IdentityAwareBinaryConverter();

  final _messageController = StreamController<MultiplexedMessage>.broadcast();
  late final StreamSubscription<Uint8List> _subscription;

  Stream<MultiplexedMessage> get messages => _messageController.stream;

  void _handleIncomingMessage(Uint8List frame) {
    if (frame.isEmpty) return;
    int offset = 0;

    // Read ChannelID (ULEB128)
    int channelId = 0;
    int shift = 0;
    while (offset < frame.length) {
      int byte = frame[offset++];
      channelId |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }

    if (offset >= frame.length) {
      throw FormatException('Truncated envelope: missing MessageType');
    }

    // Read MessageType (1 byte)
    final typeValue = frame[offset++];
    final type = MessageType.fromValue(typeValue);

    ControlSignal? controlSignal;
    Uint8List dataBytes;

    if (type == MessageType.controlSignal) {
      if (offset >= frame.length) {
        throw FormatException('Truncated envelope: missing ControlSignal');
      }
      final signalValue = frame[offset++];
      controlSignal = ControlSignal.fromValue(signalValue);
      dataBytes = Uint8List.sublistView(frame, offset);
    } else {
      dataBytes = Uint8List.sublistView(frame, offset);
    }

    dynamic payload;
    if (dataBytes.isNotEmpty) {
      payload = _converter.deserialize(dataBytes);
    }

    _messageController.add(MultiplexedMessage(
      channelId: channelId,
      type: type,
      controlSignal: controlSignal,
      payload: payload,
    ));
  }

  Future<void> send(int channelId, MessageType type,
      {ControlSignal? controlSignal, dynamic payload}) async {
    final builder = BytesBuilder();

    // Write ChannelID (ULEB128)
    _writeUleb128(builder, channelId);

    // Write MessageType (1 byte)
    builder.addByte(type.value);

    // Write ControlSignal if present
    if (type == MessageType.controlSignal) {
      if (controlSignal == null) {
        throw ArgumentError(
            'ControlSignal must be provided for controlSignal message type');
      }
      builder.addByte(controlSignal.value);
    }

    // Write Payload data if present
    if (payload != null) {
      final serializedData = _converter.serialize(payload);
      builder.add(serializedData);
    }

    await _transport.send(builder.toBytes());
  }

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

  Future<void> close() async {
    await _subscription.cancel();
    await _messageController.close();
    await _transport.close();
  }
}
