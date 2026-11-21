import 'dart:async';
import 'dart:typed_data';

import '_flushable_web.dart' if (dart.library.io) '_flushable_vm.dart';

class StreamTransport {
  StreamTransport(
      {required Stream<List<int>> input, required StreamSink<List<int>> output})
      : _input = input,
        _output = output {
    _initReader();
  }

  final Stream<List<int>> _input;
  final StreamSink<List<int>> _output;

  final _controller = StreamController<Uint8List>.broadcast();
  final _buffer = BytesBuilder();
  late final StreamSubscription<List<int>> _subscription;
  bool _closed = false;

  Stream<Uint8List> get messages => _controller.stream;

  void _initReader() {
    _subscription = _input.listen(
      (data) {
        if (_closed) return;
        _buffer.add(data);
        _processBuffer();
      },
      onError: (err, st) {
        if (!_closed) _controller.addError(err, st);
      },
      onDone: () {
        close();
      },
      cancelOnError: false,
    );
  }

  void _processBuffer() {
    final bytes = _buffer.toBytes();
    int offset = 0;

    while (offset < bytes.length) {
      // Try to read ULEB128 length prefix
      int length = 0;
      int shift = 0;
      int bytesRead = 0;
      bool hasLength = false;

      for (int i = offset; i < bytes.length; i++) {
        int byte = bytes[i];
        bytesRead++;
        length |= (byte & 0x7F) << shift;
        if ((byte & 0x80) == 0) {
          hasLength = true;
          break;
        }
        shift += 7;
      }

      if (!hasLength) {
        // Incomplete length prefix, wait for more data
        break;
      }

      int headerSize = bytesRead;
      if (offset + headerSize + length > bytes.length) {
        // Incomplete message payload, wait for more data
        break;
      }

      // Extract message payload
      final payload = Uint8List.sublistView(
          bytes, offset + headerSize, offset + headerSize + length);
      _controller.add(payload);
      offset += headerSize + length;
    }

    // Keep remaining unread bytes in buffer
    _buffer.clear();
    if (offset < bytes.length) {
      _buffer.add(Uint8List.sublistView(bytes, offset));
    }
  }

  final _queue = <Uint8List>[];
  bool _sending = false;

  Future<void> send(Uint8List message) async {
    if (_closed) {
      throw StateError('Cannot send message on closed transport');
    }
    final builder = BytesBuilder();
    int value = message.length;
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
    builder.add(message);
    _queue.add(builder.toBytes());
    if (_sending) return;
    _sending = true;
    try {
      while (_queue.isNotEmpty) {
        final data = _queue.removeAt(0);
        _output.add(data);
        await flush(_output);
      }
    } finally {
      _sending = false;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    await _controller.close();
  }
}
