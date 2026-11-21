// ignore_for_file: file_names

import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'src/test_context.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '08_channel_multiplexer_suite.dart';

void execute(TestContext tc) {
  tc.launch(() {
    tc.group('- CHANNEL MULTIPLEXER', () {
      tc.test('Multiplex and demultiplex messages', () async {
        final inputController = StreamController<List<int>>.broadcast();
        final outputController = StreamController<List<int>>.broadcast();
        final sentFrames = <List<int>>[];
        outputController.stream.listen(sentFrames.add);

        final transport = StreamTransport(
          input: inputController.stream,
          output: outputController.sink,
        );

        final multiplexer = ChannelMultiplexer(transport);

        final received = <MultiplexedMessage>[];
        final sub = multiplexer.messages.listen(received.add);

        // Send on channel 42
        multiplexer.send(42, MessageType.request, payload: 'hello worker');
        await pumpEventQueue();

        expect(sentFrames.length, equals(1));
        inputController.add(sentFrames.last);
        await pumpEventQueue();

        expect(received.length, equals(1));
        expect(received[0].channelId, equals(42));
        expect(received[0].type, equals(MessageType.request));
        expect(received[0].payload, equals('hello worker'));

        // Send control signal
        multiplexer.send(100, MessageType.controlSignal,
            controlSignal: ControlSignal.endOfStream);
        await pumpEventQueue();

        expect(sentFrames.length, equals(2));
        inputController.add(sentFrames.last);
        await pumpEventQueue();

        expect(received.length, equals(2));
        expect(received[1].channelId, equals(100));
        expect(received[1].type, equals(MessageType.controlSignal));
        expect(received[1].controlSignal, equals(ControlSignal.endOfStream));

        await sub.cancel();
        await multiplexer.close();
        await inputController.close();
        await outputController.close();
      });
    });
  });
}
