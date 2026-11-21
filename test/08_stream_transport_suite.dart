// ignore_for_file: file_names

import 'dart:async';
import 'dart:typed_data';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'src/test_context.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '08_stream_transport_suite.dart';

void execute(TestContext tc) {
  tc.launch(() {
    tc.group('- STREAM TRANSPORT FRAMING', () {
      tc.test('Send and receive framed messages', () async {
        final inputController = StreamController<List<int>>();
        final outputController = StreamController<List<int>>();

        final transport = StreamTransport(
          input: inputController.stream,
          output: outputController.sink,
        );

        final receivedMessages = <Uint8List>[];
        final sub = transport.messages.listen(receivedMessages.add);

        // Send a message from transport
        final msg1 = Uint8List.fromList([1, 2, 3, 4]);
        transport.send(msg1);

        // Read framed output from outputController
        final outputBytes = await outputController.stream.first;
        expect(outputBytes, equals([4, 1, 2, 3, 4]));

        // Simulate incoming message from inputController
        // Length 3 -> 0x03, payload [10, 20, 30]
        inputController.add([3, 10, 20, 30]);

        await pumpEventQueue();
        expect(receivedMessages.length, equals(1));
        expect(receivedMessages[0], equals([10, 20, 30]));

        // Test fragmented payload chunks
        inputController.add([2, 40]); // length 2, partial payload [40]
        await pumpEventQueue();
        expect(receivedMessages.length, equals(1)); // not complete yet

        inputController.add([50]); // remaining payload [50]
        await pumpEventQueue();
        expect(receivedMessages.length, equals(2));
        expect(receivedMessages[1], equals([40, 50]));

        await sub.cancel();
        await transport.close();
        await inputController.close();
        await outputController.close();
      });
    });
  });
}
