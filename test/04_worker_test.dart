// ignore_for_file: file_names

import 'dart:async';
import 'dart:typed_data';

import 'package:logger/web.dart';
import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'src/memory_logger.dart';
import 'src/test_context.dart';
import 'src/utils.dart';
import 'test_constants.dart';
import 'worker_services/fraction.dart';
import 'worker_services/installable_service_worker.dart';
import 'worker_services/test_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '04_worker_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- SQUADRON PLATFORMS', () {
      tc.test('- VM', () {
        expect(Squadron.platformType.isVm, isTrue);
        expect(Squadron.platformType.isJs, isFalse);
        expect(Squadron.platformType.isWasm, isFalse);
        expect(Squadron.platformType.isWeb, isFalse);
      }, skip: !tc.runnerPlatform.isVm);

      tc.test('- JS', () {
        expect(Squadron.platformType.isVm, isFalse);
        expect(Squadron.platformType.isJs, isTrue);
        expect(Squadron.platformType.isWasm, isFalse);
        expect(Squadron.platformType.isWeb, isTrue);
      }, skip: !tc.runnerPlatform.isJs);

      tc.test('- WASM', () {
        expect(Squadron.platformType.isVm, isFalse);
        expect(Squadron.platformType.isJs, isFalse);
        expect(Squadron.platformType.isWasm, isTrue);
        expect(Squadron.platformType.isWeb, isTrue);
      }, skip: !tc.runnerPlatform.isWasm);

      tc.test('- Web', () {
        expect(Squadron.platformType.isVm, isFalse);
        expect(Squadron.platformType.isWeb, isTrue);
      }, skip: !tc.runnerPlatform.isWeb);
    });

    tc.group('- TARGET PLATFORMS', () {
      tc.test('- VM', () {
        expect(TargetPlatform.all.hasVm, isTrue);
        expect(TargetPlatform.vm.hasVm, isTrue);
        expect(TargetPlatform.js.hasVm, isFalse);
        expect(TargetPlatform.wasm.hasVm, isFalse);
        expect(TargetPlatform.web.hasVm, isFalse);
      });

      tc.test('- JS', () {
        expect(TargetPlatform.all.hasJs, isTrue);
        expect(TargetPlatform.vm.hasJs, isFalse);
        expect(TargetPlatform.js.hasJs, isTrue);
        expect(TargetPlatform.wasm.hasJs, isFalse);
        expect(TargetPlatform.web.hasJs, isTrue);
      });

      tc.test('- WASM', () {
        expect(TargetPlatform.all.hasWasm, isTrue);
        expect(TargetPlatform.vm.hasWasm, isFalse);
        expect(TargetPlatform.js.hasWasm, isFalse);
        expect(TargetPlatform.wasm.hasWasm, isTrue);
        expect(TargetPlatform.web.hasWasm, isTrue);
      });
    });

    tc.group('- ANNOTATIONS', () {
      tc.test('- VM', () {
        expect(vmService.local, isFalse);
        expect(vmService.pool, isTrue);
        expect(vmService.targetPlatform.hasVm, isTrue);
        expect(vmService.targetPlatform.hasJs, isFalse);
        expect(vmService.targetPlatform.hasWasm, isFalse);
      });

      tc.test('- JS', () {
        final jsService = SquadronService(
            baseUrl: '~/', pool: true, targetPlatform: TargetPlatform.js);
        expect(jsService.baseUrl, '~/');
        expect(jsService.local, isFalse);
        expect(jsService.pool, isTrue);
        expect(jsService.targetPlatform.hasVm, isFalse);
        expect(jsService.targetPlatform.hasJs, isTrue);
        expect(jsService.targetPlatform.hasWasm, isFalse);
      });

      tc.test('- WASM', () {
        final wasmService = SquadronService(
            baseUrl: '~/', pool: true, targetPlatform: TargetPlatform.wasm);
        expect(wasmService.baseUrl, '~/');
        expect(wasmService.local, isFalse);
        expect(wasmService.pool, isTrue);
        expect(wasmService.targetPlatform.hasVm, isFalse);
        expect(wasmService.targetPlatform.hasJs, isFalse);
        expect(wasmService.targetPlatform.hasWasm, isTrue);
      });

      tc.test('- WEB', () {
        final wasmService = SquadronService.web(baseUrl: '~/', pool: true);
        expect(wasmService.baseUrl, '~/');
        expect(wasmService.local, isFalse);
        expect(wasmService.pool, isTrue);
        expect(wasmService.targetPlatform.hasVm, isFalse);
        expect(wasmService.targetPlatform.hasJs, isTrue);
        expect(wasmService.targetPlatform.hasWasm, isTrue);
      });

      tc.test('- ALL', () {
        final wasmService = SquadronService(baseUrl: '~/', pool: true);
        expect(wasmService.baseUrl, '~/');
        expect(wasmService.local, isFalse);
        expect(wasmService.pool, isTrue);
        expect(wasmService.targetPlatform.hasVm, isTrue);
        expect(wasmService.targetPlatform.hasJs, isTrue);
        expect(wasmService.targetPlatform.hasWasm, isTrue);
      });

      tc.test('- ALL - no pool', () {
        final wasmService = SquadronService(baseUrl: '~/', pool: false);
        expect(wasmService.baseUrl, '~/');
        expect(wasmService.local, isFalse);
        expect(wasmService.pool, isFalse);
        expect(wasmService.targetPlatform.hasVm, isTrue);
        expect(wasmService.targetPlatform.hasJs, isTrue);
        expect(wasmService.targetPlatform.hasWasm, isTrue);
      });
    });

    tc.group('- SQUADRON WORKER - START/STOP', () {
      tc.test('- Start & stop', () async {
        await TestWorker(tc).useAsync((w) async {
          expect(w.isConnected, isFalse);
          var stats = w.getStats();
          expect(stats.upTime, Duration.zero);
          expect(stats.idleTime, greaterThanOrEqualTo(Duration.zero));
          expect(stats.activeConnections, isZero);
          expect(stats.isStopped, isFalse);

          final channel = await w.start();
          expect(channel, isNotNull);
          expect(w.isConnected, isTrue);

          await Future.delayed(delay_80ms * 2);
          stats = w.getStats();
          expect(stats.upTime, greaterThanOrEqualTo(delay_80ms));
          expect(stats.activeConnections, isZero);
          expect(stats.isStopped, isFalse);
          expect(stats.idleTime, lessThanOrEqualTo(stats.upTime));

          w.stop();
          stats = w.getStats();
          expect(stats.isStopped, isTrue);
          final upTime = stats.upTime;
          expect(w.isConnected, isFalse);
          expect(stats.activeConnections, isZero);
          expect(stats.upTime, greaterThan(Duration.zero));

          await Future.delayed(delay_80ms);
          stats = w.getStats();
          expect(stats.upTime, upTime);
          expect(stats.idleTime, greaterThanOrEqualTo(delay_80ms));
        });
      });

      tc.test('- Start & terminate (sync)', () async {
        await TestWorker(tc).useAsync((w) async {
          expect(w.isConnected, isFalse);
          var stats = w.getStats();
          expect(stats.upTime, Duration.zero);
          expect(stats.idleTime, greaterThanOrEqualTo(Duration.zero));
          expect(stats.activeConnections, isZero);
          expect(stats.isStopped, isFalse);

          final channel = await w.start();
          expect(channel, isNotNull);
          expect(w.isConnected, isTrue);

          await Future.delayed(delay_80ms * 2);
          stats = w.getStats();
          expect(stats.upTime, greaterThanOrEqualTo(delay_80ms));
          expect(stats.idleTime, lessThanOrEqualTo(stats.upTime));
          expect(stats.activeConnections, isZero);
          expect(stats.isStopped, isFalse);

          final duration = delay_80ms * 4;
          Future.delayed(duration * 0.5, () {
            w.terminate();
            stats = w.getStats();
            expect(stats.activeConnections, isZero);
            expect(stats.isStopped, isTrue);
            expect(w.isConnected, isFalse);
          });

          try {
            await w.cpu(ms: duration.inMilliseconds);
            throw unexpectedSuccess('cpu completed after termination');
          } on TaskTerminatedException {
            // expected: the "cpu" task has been terminated
          }

          stats = w.getStats();
          final upTime = stats.upTime;
          expect(stats.upTime, greaterThan(Duration.zero));
          expect(stats.activeConnections, isZero);

          await Future.delayed(delay_80ms);
          stats = w.getStats();
          expect(stats.upTime, upTime);
          expect(stats.idleTime, greaterThanOrEqualTo(delay_80ms));
          expect(stats.activeConnections, isZero);
        });
      });

      tc.test('- Start & terminate (async)', () async {
        await TestWorker(tc).useAsync((w) async {
          expect(w.isConnected, isFalse);
          var stats = w.getStats();
          expect(stats.upTime, Duration.zero);
          expect(stats.idleTime, greaterThanOrEqualTo(Duration.zero));
          expect(stats.activeConnections, isZero);
          expect(stats.isStopped, isFalse);

          final channel = await w.start();
          expect(channel, isNotNull);
          expect(w.isConnected, isTrue);

          await Future.delayed(delay_80ms * 2);
          stats = w.getStats();
          expect(stats.upTime, greaterThanOrEqualTo(delay_80ms));
          expect(stats.idleTime, lessThanOrEqualTo(stats.upTime));
          expect(stats.activeConnections, isZero);
          expect(stats.isStopped, isFalse);

          final duration = delay_80ms * 4;
          Future.delayed(duration * 0.5, () {
            w.terminate();
            stats = w.getStats();
            expect(stats.activeConnections, isZero);
            expect(stats.isStopped, isTrue);
            expect(w.isConnected, isFalse);
          });

          try {
            await w.io(ms: duration.inMilliseconds);
            throw unexpectedSuccess('io completed after termination');
          } on TaskTerminatedException {
            // expected: the "io" task has been terminated
          }

          stats = w.getStats();
          final savedUpTime = stats.upTime;
          expect(stats.upTime, greaterThan(Duration.zero));
          expect(stats.activeConnections, isZero);

          await Future.delayed(delay_80ms);
          stats = w.getStats();
          expect(stats.upTime, savedUpTime);
          expect(stats.idleTime, greaterThanOrEqualTo(delay_80ms));
          expect(stats.activeConnections, isZero);
        });
      });

      tc.test('- Hook installation', () async {
        String? status;
        void hook(PlatformThread pw) {
          status = 'hook called';
        }

        await TestWorker(tc, hook: hook).useAsync((w) async {
          expect(status, isNull);
          await w.start();
          expect(status, matches('hook called'));
        });
      });

      tc.test('- Service installation', () async {
        await InstallableWorker(tc).useAsync((w) async {
          final logger = MemoryLogger();
          logger.level = Level.all;
          w.channelLogger = logger;
          await w.start();

          expect(await w.isInstalled(), isTrue);
          expect(await w.isUninstalled(), isFalse);

          // log forwarding is asynchronous, make sure they have time to arrive
          await Future.delayed(delay_20ms);
          expect(logger.logs, mentions('service installed'));
          expect(logger.logs, doesNotMention('intended failure'));

          // stopping the worker uninstalls the service
          w.stop();

          // log forwarding is asynchronous, make sure they have time to arrive
          await Future.delayed(delay_20ms);
          expect(logger.logs, mentions('service uninstalled'));
          expect(logger.logs, doesNotMention('intended failure'));
        });
      });

      tc.test('- Cannot restart after stop', () async {
        await TestWorker(tc).useAsync((w) async {
          await w.start();
          expect(w.getStats().isStopped, isFalse);

          await Future.delayed(delay_80ms);

          w.stop();
          expect(w.getStats().isStopped, isTrue);

          await Future.delayed(delay_80ms);

          try {
            final res = await w.start();
            throw unexpectedSuccess('start()', res);
          } on WorkerException catch (ex) {
            expect(ex, reports('worker is stopped'));
          }

          expect(w.getStats().activeConnections, isZero);
        });
      });
    });

    tc.group('- SQUADRON WORKER - NON-STREAMING', () {
      tc.test('- Platform type', () async {
        await TestWorker(tc).useAsync((w) async {
          // make sure platforms match with the test context
          expect(Squadron.platformType, tc.runnerPlatform);
          final workerPlatform = await w.getPlatformType();
          expect(workerPlatform, tc.workerPlatform);
        });
      });

      tc.test('- Sending maps with BigInts', () async {
        await TestWorker(tc).useAsync((w) async {
          final input = {
            BigInt.one.toString(): BigInt.one,
            BigInt.two.toString(): BigInt.two,
          };
          final res = await w.map(input);
          expect(res, {
            BigInt.one: BigInt.one.toString(),
            BigInt.two: BigInt.two.toString(),
          });
        });
      });

      tc.test('- Sending sets with BigInts', () async {
        await TestWorker(tc).useAsync((w) async {
          final input = {BigInt.one, BigInt.two};
          final res = await w.set(input);
          expect(res, {BigInt.two, BigInt.two * BigInt.two});
        });
      });

      tc.test('- Sending TypedData - different instances', () async {
        await TestWorker(tc).useAsync((w) async {
          final a = Uint32List.fromList([1, 2, 3]);
          final b = Uint32List.fromList([1, 2, 3]);
          final res = await w.checkBuffers(a, b);
          expect(res, isFalse);
        });
      });

      tc.test('- Sending TypedData - same instances', () async {
        await TestWorker(tc).useAsync((w) async {
          final a = Uint32List.fromList([1, 2, 3]);
          final res = await w.checkBuffers(a, a);
          if (tc.workerPlatform.isVm) {
            expect(res, isFalse);
          } else if (tc.workerPlatform.isJs) {
            // identity is retained when using JS worker
            expect(res, isTrue);
          } else if (tc.workerPlatform.isWasm) {
            expect(res, isFalse);
          }
        });
      });

      tc.test('- Sending TypedData - same buffer', () async {
        await TestWorker(tc).useAsync((w) async {
          final a = Float32List(8);
          final b = a.buffer.asUint8List();
          final res = await w.checkBuffers(a, b);
          if (tc.workerPlatform.isVm) {
            expect(res, isFalse);
          } else if (tc.workerPlatform.isJs) {
            if (tc.runnerPlatform.isJs) {
              // identity is retained when using JS client + JS worker
              expect(res, isTrue);
            } else {
              expect(res, isFalse);
            }
          } else if (tc.workerPlatform.isWasm) {
            expect(res, isFalse);
          }
        });
      });

      tc.test('- Identity - different instances', () async {
        await TestWorker(tc).useAsync((w) async {
          final a = Fraction(1, 2);
          final b = Fraction(1, 2);
          final res = await w.checkFractions(a, b);
          expect(res, isFalse);
        });
      });

      tc.test('- Identity - same instances', () async {
        await TestWorker(tc).useAsync((w) async {
          final a = Fraction(1, 2);
          final res = await w.checkFractions(a, a);
          expect(res, isTrue);
        });
      });

      tc.test('- Sequential workloads', () async {
        await TestWorker(tc).useAsync((w) async {
          int taskId = 0;
          final completedTasks = <int>[];
          Future createTask(Duration duration) {
            final id = ++taskId;
            return w
                .io(ms: duration.inMilliseconds)
                .whenComplete(() => completedTasks.add(id));
          }

          var stats = w.getStats();
          expect(stats.workload, isZero);
          expect(stats.maxWorkload, isZero);
          expect(stats.totalWorkload, isZero);

          await createTask(delay_80ms); // task #1

          expect(completedTasks, contains(1)); // #1 has completed
          stats = w.getStats();
          expect(stats.workload, isZero);
          expect(stats.maxWorkload, 1);
          expect(stats.totalWorkload, 1);

          final task = createTask(delay_80ms * 3); // task #2

          expect(completedTasks, contains(1)); // #2 is pending
          stats = w.getStats();
          expect(stats.workload, 1);
          expect(stats.maxWorkload, 1);
          expect(stats.totalWorkload, 1);

          await Future.delayed(delay_80ms);

          expect(completedTasks, contains(1)); // #2 is still pending
          stats = w.getStats();
          expect(stats.workload, 1);
          expect(stats.maxWorkload, 1);
          expect(stats.totalWorkload, 1);

          await task;

          expect(completedTasks, containsAll([1, 2])); // #2 has completed
          stats = w.getStats();
          expect(stats.workload, isZero);
          expect(stats.maxWorkload, 1);
          expect(stats.totalWorkload, 2);

          await createTask(delay_80ms); // task #3

          expect(completedTasks, containsAll([1, 2, 3])); // #3 has completed
          stats = w.getStats();
          expect(stats.workload, isZero);
          expect(stats.maxWorkload, 1);
          expect(stats.totalWorkload, 3);

          w.stop();

          stats = w.getStats();
          expect(stats.workload, isZero);
          expect(stats.maxWorkload, 1);
          expect(stats.totalWorkload, 3);
          expect(stats.upTime, greaterThanOrEqualTo(delay_80ms * 5));
        });
      });

      tc.test('- Parallel workloads', () async {
        await TestWorker(tc).useAsync((w) async {
          int taskId = 0;
          final completedTasks = <int>[];
          Future createTask(Duration duration) {
            final id = ++taskId;
            return w
                .io(ms: duration.inMilliseconds + 50)
                .whenComplete(() => completedTasks.add(id));
          }

          await w.start();

          var stats = w.getStats();
          expect(stats.workload, isZero);
          expect(stats.maxWorkload, isZero);
          expect(stats.totalWorkload, isZero);

          var tasks = [
            createTask(delay_80ms), // task 1
            createTask(delay_80ms * 5), // task 2
            createTask(delay_80ms * 3), // task 3
          ];

          expect(completedTasks, isEmpty);
          stats = w.getStats();
          expect(stats.workload, 3);
          expect(stats.maxWorkload, 3);
          expect(stats.totalWorkload, isZero);

          await Future.wait(tasks);

          // all tasks have completed
          expect(completedTasks, containsAll([1, 2, 3]));
          stats = w.getStats();
          expect(stats.workload, isZero);
          expect(stats.maxWorkload, 3);
          expect(stats.totalWorkload, 3);
          expect(stats.upTime, greaterThanOrEqualTo(delay_80ms * 5));
          expect(stats.upTime, lessThanOrEqualTo(delay_80ms * 7));

          /////////// time origin for next tasks ///////////

          completedTasks.clear();
          createTask(delay_80ms * 9); // #4 complete at ~9 delays
          createTask(delay_80ms * 5); // #5 complete at ~5 delays
          createTask(delay_80ms * 3); // #6 complete at ~3 delays

          expect(completedTasks, isEmpty);
          stats = w.getStats();
          expect(stats.workload, 3);
          expect(stats.maxWorkload, 3);
          expect(stats.totalWorkload, 3);

          // 1 delay: all tasks still pending
          await Future.delayed(delay_80ms);
          expect(completedTasks, isEmpty);
          stats = w.getStats();
          expect(stats.workload, 3);
          expect(stats.maxWorkload, 3);
          expect(stats.totalWorkload, 3);

          // 4 delays: #6 has completed
          await Future.delayed(delay_80ms * 3);
          expect(completedTasks, contains(6));
          stats = w.getStats();
          expect(stats.workload, 2);
          expect(stats.maxWorkload, 3);
          expect(stats.totalWorkload, 4);

          createTask(delay_80ms * 5); // #7 completes at ~9 delays
          createTask(delay_80ms * 3); // #8 completes at ~7 delays

          expect(completedTasks, contains(6));
          stats = w.getStats();
          expect(stats.workload, 4);
          expect(stats.maxWorkload, 4);
          expect(stats.totalWorkload, 4);

          // 8 delays: #5 and #8 have completed
          await Future.delayed(delay_80ms * 4);
          expect(completedTasks, containsAll([5, 6, 8]));
          stats = w.getStats();
          expect(stats.workload, 2);
          expect(stats.maxWorkload, 4);
          expect(stats.totalWorkload, 6);

          // 11 delays: all tasks have completed
          await Future.delayed(delay_80ms * 3);
          expect(completedTasks, containsAll([4, 5, 6, 7, 8]));
          stats = w.getStats();
          expect(stats.workload, isZero);
          expect(stats.maxWorkload, 4);
          expect(stats.totalWorkload, 8);

          w.stop();
          stats = w.getStats();
          expect(stats.workload, isZero);
          expect(stats.maxWorkload, 4);
          expect(stats.totalWorkload, 8);
          expect(stats.upTime, greaterThanOrEqualTo(delay_80ms * 16));
          expect(stats.upTime, lessThan(delay_80ms * 19));
        });
      });
    });
  });
}
