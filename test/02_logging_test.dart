// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'package:logger/logger.dart';
import 'package:test/test.dart';

import 'classes/memory_logger.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/log_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '02_logging_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group("- Logging", () {
      final logger = MemoryLogger();
      late LogWorker worker;

      tc.setUpAll(() async {
        worker = LogWorker(tc);
        worker.channelLogger = logger;
        await worker.start();
      });

      tc.tearDownAll(() {
        worker.stop();
      });

      setUp(() {
        logger.clear();
        logger.level = Level.all;
      });

      tearDown(() {
        logger.clear();
      });

      tc.test('off', () async {
        await worker.setLevel(Level.off.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await pumpEventQueue();
        expect(logger.logs, doesNotMention('trace'));
        expect(logger.logs, doesNotMention('debug'));
        expect(logger.logs, doesNotMention('info'));
        expect(logger.logs, doesNotMention('warning'));
        expect(logger.logs, doesNotMention('error'));
        expect(logger.logs, doesNotMention('fatal'));
      });

      tc.test('>= fatal', () async {
        await worker.setLevel(Level.fatal.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await pumpEventQueue();
        expect(logger.logs, doesNotMention('trace'));
        expect(logger.logs, doesNotMention('debug'));
        expect(logger.logs, doesNotMention('info'));
        expect(logger.logs, doesNotMention('warning'));
        expect(logger.logs, doesNotMention('error'));
        expect(logger.logs, mentions('fatal'));
      });

      tc.test('>= error', () async {
        await worker.setLevel(Level.error.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await pumpEventQueue();
        expect(logger.logs, doesNotMention('trace'));
        expect(logger.logs, doesNotMention('debug'));
        expect(logger.logs, doesNotMention('info'));
        expect(logger.logs, doesNotMention('warning'));
        expect(logger.logs, mentions('error'));
        expect(logger.logs, mentions('fatal'));
      });

      tc.test('>= warning', () async {
        await worker.setLevel(Level.warning.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await pumpEventQueue();
        expect(logger.logs, doesNotMention('trace'));
        expect(logger.logs, doesNotMention('debug'));
        expect(logger.logs, doesNotMention('info'));
        expect(logger.logs, mentions('warning'));
        expect(logger.logs, mentions('error'));
        expect(logger.logs, mentions('fatal'));
      });

      tc.test('>= info', () async {
        await worker.setLevel(Level.info.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await pumpEventQueue();
        expect(logger.logs, doesNotMention('trace'));
        expect(logger.logs, doesNotMention('debug'));
        expect(logger.logs, mentions('info'));
        expect(logger.logs, mentions('warning'));
        expect(logger.logs, mentions('error'));
        expect(logger.logs, mentions('fatal'));
      });

      tc.test('>= debug', () async {
        await worker.setLevel(Level.debug.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await pumpEventQueue();
        expect(logger.logs, doesNotMention('trace'));
        expect(logger.logs, mentions('debug'));
        expect(logger.logs, mentions('info'));
        expect(logger.logs, mentions('warning'));
        expect(logger.logs, mentions('error'));
        expect(logger.logs, mentions('fatal'));
      });

      tc.test('>= trace', () async {
        await worker.setLevel(Level.trace.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await pumpEventQueue();
        expect(logger.logs, mentions('trace'));
        expect(logger.logs, mentions('debug'));
        expect(logger.logs, mentions('info'));
        expect(logger.logs, mentions('warning'));
        expect(logger.logs, mentions('error'));
        expect(logger.logs, mentions('fatal'));
      });

      tc.test('all', () async {
        await worker.setLevel(Level.all.value);
        await worker.log();
        // log forwarding is asynchronous, make sure they have time to arrive
        await pumpEventQueue();
        expect(logger.logs, mentions('trace'));
        expect(logger.logs, mentions('debug'));
        expect(logger.logs, mentions('info'));
        expect(logger.logs, mentions('warning'));
        expect(logger.logs, mentions('error'));
        expect(logger.logs, mentions('fatal'));
      });
    });
  });
}
