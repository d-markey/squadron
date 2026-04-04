// ignore_for_file: file_names

import 'package:logger/logger.dart';
import 'package:test/test.dart';

import 'src/memory_logger.dart';
import 'src/test_context.dart';
import 'src/utils.dart';
import 'test_delay.dart';
import 'test_extensions.dart';
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

      tc.test(
          'Level.off',
          () => LogWorker(tc).runTest((w) async {
                w.channelLogger = logger;
                await w.setLevel(Level.off.value);
                await w.log();
                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelay.tick);
                expect(logger.logs, doesNotMention('trace'));
                expect(logger.logs, doesNotMention('debug'));
                expect(logger.logs, doesNotMention('info'));
                expect(logger.logs, doesNotMention('warning'));
                expect(logger.logs, doesNotMention('error'));
                expect(logger.logs, doesNotMention('fatal'));
              }));

      tc.test(
          'Level.fatal',
          () => LogWorker(tc).runTest((w) async {
                w.channelLogger = logger;
                await w.setLevel(Level.fatal.value);
                await w.log();
                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelay.tick);
                expect(logger.logs, doesNotMention('trace'));
                expect(logger.logs, doesNotMention('debug'));
                expect(logger.logs, doesNotMention('info'));
                expect(logger.logs, doesNotMention('warning'));
                expect(logger.logs, doesNotMention('error'));
                expect(logger.logs, mentions('fatal'));
              }));

      tc.test(
          'Level.error',
          () => LogWorker(tc).runTest((w) async {
                w.channelLogger = logger;
                await w.setLevel(Level.error.value);
                await w.log();
                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelay.tick);
                expect(logger.logs, doesNotMention('trace'));
                expect(logger.logs, doesNotMention('debug'));
                expect(logger.logs, doesNotMention('info'));
                expect(logger.logs, doesNotMention('warning'));
                expect(logger.logs, mentions('error'));
                expect(logger.logs, mentions('fatal'));
              }));

      tc.test(
          'Level.warning',
          () => LogWorker(tc).runTest((worker) async {
                worker.channelLogger = logger;
                await worker.setLevel(Level.warning.value);
                await worker.log();
                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelay.tick);
                expect(logger.logs, doesNotMention('trace'));
                expect(logger.logs, doesNotMention('debug'));
                expect(logger.logs, doesNotMention('info'));
                expect(logger.logs, mentions('warning'));
                expect(logger.logs, mentions('error'));
                expect(logger.logs, mentions('fatal'));
              }));

      tc.test(
          'Level.info',
          () => LogWorker(tc).runTest((worker) async {
                worker.channelLogger = logger;
                await worker.setLevel(Level.info.value);
                await worker.log();
                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelay.tick);
                expect(logger.logs, doesNotMention('trace'));
                expect(logger.logs, doesNotMention('debug'));
                expect(logger.logs, mentions('info'));
                expect(logger.logs, mentions('warning'));
                expect(logger.logs, mentions('error'));
                expect(logger.logs, mentions('fatal'));
              }));

      tc.test(
          'Level.debug',
          () => LogWorker(tc).runTest((w) async {
                w.channelLogger = logger;
                await w.setLevel(Level.debug.value);
                await w.log();
                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelay.tick);
                expect(logger.logs, doesNotMention('trace'));
                expect(logger.logs, mentions('debug'));
                expect(logger.logs, mentions('info'));
                expect(logger.logs, mentions('warning'));
                expect(logger.logs, mentions('error'));
                expect(logger.logs, mentions('fatal'));
              }));

      tc.test(
          'Level.trace',
          () => LogWorker(tc).runTest((w) async {
                w.channelLogger = logger;
                await w.setLevel(Level.trace.value);
                await w.log();
                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelay.tick);
                expect(logger.logs, mentions('trace'));
                expect(logger.logs, mentions('debug'));
                expect(logger.logs, mentions('info'));
                expect(logger.logs, mentions('warning'));
                expect(logger.logs, mentions('error'));
                expect(logger.logs, mentions('fatal'));
              }));

      tc.test(
          'Level.all',
          () => LogWorker(tc).runTest((w) async {
                w.channelLogger = logger;
                await w.setLevel(Level.all.value);
                await w.log();
                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelay.tick);
                expect(logger.logs, mentions('trace'));
                expect(logger.logs, mentions('debug'));
                expect(logger.logs, mentions('info'));
                expect(logger.logs, mentions('warning'));
                expect(logger.logs, mentions('error'));
                expect(logger.logs, mentions('fatal'));
              }));
    });
  });
}
