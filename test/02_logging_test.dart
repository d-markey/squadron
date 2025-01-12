// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'src/memory_logger.dart';
import 'src/test_context.dart';
import 'src/utils.dart';
import 'test_constants.dart';
import 'worker_services/log_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '02_logging_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- LOGGING', () {
      final logger = MemoryLogger();

      setUp(() {
        logger.clear();
        logger.level = Level.all;
      });

      tearDown(() {
        logger.clear();
      });

      tc.test('Level.off', () async {
        await LogWorker(tc).useAsync((w) async {
          w.channelLogger = logger;
          await w.setLevel(Level.off.value);
          await w.log();
          // log forwarding is asynchronous, make sure they have time to arrive
          await Future.delayed(delay_20ms);
          expect(logger.logs, doesNotMention('trace'));
          expect(logger.logs, doesNotMention('debug'));
          expect(logger.logs, doesNotMention('info'));
          expect(logger.logs, doesNotMention('warning'));
          expect(logger.logs, doesNotMention('error'));
          expect(logger.logs, doesNotMention('fatal'));
        });
      });

      tc.test('Level.fatal', () async {
        await LogWorker(tc).useAsync((w) async {
          w.channelLogger = logger;
          await w.setLevel(Level.fatal.value);
          await w.log();
          // log forwarding is asynchronous, make sure they have time to arrive
          await Future.delayed(delay_20ms);
          expect(logger.logs, doesNotMention('trace'));
          expect(logger.logs, doesNotMention('debug'));
          expect(logger.logs, doesNotMention('info'));
          expect(logger.logs, doesNotMention('warning'));
          expect(logger.logs, doesNotMention('error'));
          expect(logger.logs, mentions('fatal'));
        });
      });

      tc.test('Level.error', () async {
        await LogWorker(tc).useAsync((w) async {
          w.channelLogger = logger;
          await w.setLevel(Level.error.value);
          await w.log();
          // log forwarding is asynchronous, make sure they have time to arrive
          await Future.delayed(delay_20ms);
          expect(logger.logs, doesNotMention('trace'));
          expect(logger.logs, doesNotMention('debug'));
          expect(logger.logs, doesNotMention('info'));
          expect(logger.logs, doesNotMention('warning'));
          expect(logger.logs, mentions('error'));
          expect(logger.logs, mentions('fatal'));
        });
      });

      tc.test('Level.warning', () async {
        await LogWorker(tc).useAsync((worker) async {
          worker.channelLogger = logger;
          await worker.setLevel(Level.warning.value);
          await worker.log();
          // log forwarding is asynchronous, make sure they have time to arrive
          await Future.delayed(delay_20ms);
          expect(logger.logs, doesNotMention('trace'));
          expect(logger.logs, doesNotMention('debug'));
          expect(logger.logs, doesNotMention('info'));
          expect(logger.logs, mentions('warning'));
          expect(logger.logs, mentions('error'));
          expect(logger.logs, mentions('fatal'));
        });
      });

      tc.test('Level.info', () async {
        await LogWorker(tc).useAsync((worker) async {
          worker.channelLogger = logger;
          await worker.setLevel(Level.info.value);
          await worker.log();
          // log forwarding is asynchronous, make sure they have time to arrive
          await Future.delayed(delay_20ms);
          expect(logger.logs, doesNotMention('trace'));
          expect(logger.logs, doesNotMention('debug'));
          expect(logger.logs, mentions('info'));
          expect(logger.logs, mentions('warning'));
          expect(logger.logs, mentions('error'));
          expect(logger.logs, mentions('fatal'));
        });
      });

      tc.test('Level.debug', () async {
        await LogWorker(tc).useAsync((w) async {
          w.channelLogger = logger;
          await w.setLevel(Level.debug.value);
          await w.log();
          // log forwarding is asynchronous, make sure they have time to arrive
          await Future.delayed(delay_20ms);
          expect(logger.logs, doesNotMention('trace'));
          expect(logger.logs, mentions('debug'));
          expect(logger.logs, mentions('info'));
          expect(logger.logs, mentions('warning'));
          expect(logger.logs, mentions('error'));
          expect(logger.logs, mentions('fatal'));
        });
      });

      tc.test('Level.trace', () async {
        await LogWorker(tc).useAsync((w) async {
          w.channelLogger = logger;
          await w.setLevel(Level.trace.value);
          await w.log();
          // log forwarding is asynchronous, make sure they have time to arrive
          await Future.delayed(delay_20ms);
          expect(logger.logs, mentions('trace'));
          expect(logger.logs, mentions('debug'));
          expect(logger.logs, mentions('info'));
          expect(logger.logs, mentions('warning'));
          expect(logger.logs, mentions('error'));
          expect(logger.logs, mentions('fatal'));
        });
      });

      tc.test('Level.all', () async {
        await LogWorker(tc).useAsync((w) async {
          w.channelLogger = logger;
          await w.setLevel(Level.all.value);
          await w.log();
          // log forwarding is asynchronous, make sure they have time to arrive
          await Future.delayed(delay_20ms);
          expect(logger.logs, mentions('trace'));
          expect(logger.logs, mentions('debug'));
          expect(logger.logs, mentions('info'));
          expect(logger.logs, mentions('warning'));
          expect(logger.logs, mentions('error'));
          expect(logger.logs, mentions('fatal'));
        });
      });
    });
  });
}
