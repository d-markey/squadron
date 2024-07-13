@TestOn('vm || browser')
library;

import 'package:logger/logger.dart';
import 'package:test/test.dart';

import 'classes/memory_logger.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/test_service_worker.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

String testScript = 'logging_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    final logs = <String>[];
    final memoryLogger = MemoryLogger(logs, MemoryLogFilter());

    tc.group("- Logging", () {
      late TestWorker worker;

      setUpAll(() async {
        worker = TestWorker(tc);
        worker.channelLogger = memoryLogger;
        await worker.start();
      });

      tearDownAll(() async {
        worker.release();
      });

      setUp(() {
        memoryLogger.clear();
        memoryLogger.level = Level.all;
      });

      tearDown(() {
        memoryLogger.clear();
      });

      tc.test('off', () async {
        await worker.setLevel(Level.off.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await Future.delayed(Duration.zero);
        expect(logs, doesNotMention('trace'));
        expect(logs, doesNotMention('debug'));
        expect(logs, doesNotMention('info'));
        expect(logs, doesNotMention('warning'));
        expect(logs, doesNotMention('error'));
        expect(logs, doesNotMention('fatal'));
      });

      tc.test('>= fatal', () async {
        await worker.setLevel(Level.fatal.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await Future.delayed(Duration.zero);
        expect(logs, doesNotMention('trace'));
        expect(logs, doesNotMention('debug'));
        expect(logs, doesNotMention('info'));
        expect(logs, doesNotMention('warning'));
        expect(logs, doesNotMention('error'));
        expect(logs, mentions('fatal'));
      });

      tc.test('>= error', () async {
        await worker.setLevel(Level.error.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await Future.delayed(Duration.zero);
        expect(logs, doesNotMention('trace'));
        expect(logs, doesNotMention('debug'));
        expect(logs, doesNotMention('info'));
        expect(logs, doesNotMention('warning'));
        expect(logs, mentions('error'));
        expect(logs, mentions('fatal'));
      });

      tc.test('>= warning', () async {
        await worker.setLevel(Level.warning.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await Future.delayed(Duration.zero);
        expect(logs, doesNotMention('trace'));
        expect(logs, doesNotMention('debug'));
        expect(logs, doesNotMention('info'));
        expect(logs, mentions('warning'));
        expect(logs, mentions('error'));
        expect(logs, mentions('fatal'));
      });

      tc.test('>= info', () async {
        await worker.setLevel(Level.info.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await Future.delayed(Duration.zero);
        expect(logs, doesNotMention('trace'));
        expect(logs, doesNotMention('debug'));
        expect(logs, mentions('info'));
        expect(logs, mentions('warning'));
        expect(logs, mentions('error'));
        expect(logs, mentions('fatal'));
      });

      tc.test('>= debug', () async {
        await worker.setLevel(Level.debug.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await Future.delayed(Duration.zero);
        expect(logs, doesNotMention('trace'));
        expect(logs, mentions('debug'));
        expect(logs, mentions('info'));
        expect(logs, mentions('warning'));
        expect(logs, mentions('error'));
        expect(logs, mentions('fatal'));
      });

      tc.test('>= trace', () async {
        await worker.setLevel(Level.trace.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await Future.delayed(Duration.zero);
        expect(logs, mentions('trace'));
        expect(logs, mentions('debug'));
        expect(logs, mentions('info'));
        expect(logs, mentions('warning'));
        expect(logs, mentions('error'));
        expect(logs, mentions('fatal'));
      });

      tc.test('all', () async {
        await worker.setLevel(Level.all.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await Future.delayed(Duration.zero);
        expect(logs, mentions('trace'));
        expect(logs, mentions('debug'));
        expect(logs, mentions('info'));
        expect(logs, mentions('warning'));
        expect(logs, mentions('error'));
        expect(logs, mentions('fatal'));
      });
    });
  });
}
