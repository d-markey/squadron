@TestOn('vm || browser')
library;

import 'dart:async';

import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/custom_exception.dart';
import 'classes/memory_logger.dart';
import 'classes/platform.dart';
import 'classes/prime_numbers.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/cache_service_worker.dart';
import 'worker_services/installable_service_worker.dart';
import 'worker_services/prime_service_worker.dart';
import 'worker_services/test_service.dart';
import 'worker_services/test_service_worker.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

void execute(TestContext testContext) => testContext.run(() {
      group("- Squadron Worker", () {
        final logs = <String>[];
        final memoryLogger = MemoryLogger(logs, MemoryLogFilter());

        group('- start/stop', () {
          setUp(() {
            memoryLogger.clear();
            memoryLogger.level = Level.all;
          });

          tearDown(() {
            memoryLogger.clear();
          });

          test('- start & stop', () async {
            final worker = TestWorker(testContext);
            worker.channelLogger = memoryLogger;

            await Future.delayed(TestService.shortDelay);
            expect(worker.channel, isNull);
            expect(worker.upTime, Duration.zero);
            expect(worker.idleTime, Duration.zero);
            expect(worker.isStopped, isFalse);

            final channel = await worker.start();
            expect(worker.channel, isNotNull);
            expect(channel, equals(worker.channel));

            await Future.delayed(TestService.shortDelay);
            expect(worker.upTime, greaterThan(Duration.zero));
            expect(worker.isStopped, false);

            var upTime = worker.upTime;
            expect(upTime, greaterThan(Duration.zero));
            expect(worker.idleTime, greaterThanOrEqualTo(upTime));

            worker.stop();
            expect(worker.isStopped, isTrue);

            upTime = worker.upTime;
            expect(worker.channel, isNull);
            expect(worker.upTime, greaterThan(Duration.zero));

            await Future.delayed(TestService.shortDelay);

            expect(worker.upTime, equals(upTime));
            expect(worker.idleTime, greaterThan(worker.upTime));
          });

          test('- hook', () async {
            String? threadTypeName;

            void hook(PlatformThread pw) {
              threadTypeName = pw.runtimeType.toString();
            }

            final worker = TestWorker(testContext, hook);
            worker.channelLogger = memoryLogger;

            await Future.delayed(TestService.shortDelay);
            expect(threadTypeName, isNull);

            await worker.start();
            expect(
              threadTypeName,
              equals((testContext.clientPlatform.isJs)
                  ? 'Worker'
                  : ((testContext.clientPlatform.isWasm)
                      ? 'JSValue'
                      : 'Isolate')),
            );

            worker.stop();

            await Future.delayed(TestService.shortDelay);
          });

          test('- hook failure', () async {
            String? threadTypeName;

            void hook(PlatformThread pw) {
              threadTypeName = pw.runtimeType.toString();
              throw Exception('intended exception for $threadTypeName');
            }

            final worker = TestWorker(testContext, hook);
            worker.channelLogger = memoryLogger;

            await Future.delayed(TestService.shortDelay);
            expect(threadTypeName, isNull);

            await worker.start();

            expect(
              threadTypeName,
              equals((testContext.clientPlatform.isJs)
                  ? 'Worker'
                  : ((testContext.clientPlatform.isWasm)
                      ? 'JSValue'
                      : 'Isolate')),
            );
            expect(logs, mentions('intended exception'));

            worker.stop();

            await Future.delayed(TestService.shortDelay);
          });

          group('- Install', () {
            test('No error', () async {
              final worker = InstallableWorker(testContext);
              worker.channelLogger = memoryLogger;

              await worker.start();

              expect(logs, doesNotMention('intended failure on install'));
              expect(logs, mentions('service installed successfully'));

              final installed = await worker.isInstalled();
              expect(installed, isTrue);

              final uninstalled = await worker.isUninstalled();
              expect(uninstalled, isFalse);

              worker.stop();
              expect(logs, doesNotMention('intended failure on uninstall'));
              expect(logs, doesNotMention('service uninstalled successfully'));

              await Future.delayed(TestService.delay * 2);

              expect(logs, doesNotMention('intended failure on uninstall'));
              expect(logs, mentions('service uninstalled successfully'));
            });

            test('Error on installation', () async {
              final worker =
                  InstallableWorker(testContext, throwOnInstall: true);
              worker.channelLogger = memoryLogger;

              try {
                final res = await worker.start();
                throw unexpectedSuccess('start()', res);
              } on WorkerException catch (ex) {
                lowerCaseCheck(
                    ex.message, contains('this exception is reported'));
                expect(logs, mentions('intended failure on install'));
                expect(logs, doesNotMention('service installed successfully'));
              }

              try {
                final res = await worker.isInstalled();
                throw unexpectedSuccess('isInstalled()', res);
              } on WorkerException catch (ex) {
                lowerCaseCheck(
                    ex.message, contains('this exception is reported'));
                expect(logs, mentions('intended failure on install'));
                expect(logs, doesNotMention('service installed successfully'));
              }

              worker.stop();
              expect(logs, doesNotMention('intended failure on uninstall'));
              expect(logs, doesNotMention('service uninstalled successfully'));

              await Future.delayed(TestService.delay * 2);
              expect(logs, doesNotMention('intended failure on uninstall'));
              expect(logs, doesNotMention('service uninstalled successfully'));
            });

            test('Error on uninstallation', () async {
              final worker =
                  InstallableWorker(testContext, throwOnUninstall: true);
              worker.channelLogger = memoryLogger;

              await worker.start();
              expect(logs, mentions('service installed successfully'));

              final installed = await worker.isInstalled();
              expect(installed, isTrue);

              final uninstalled = await worker.isUninstalled();
              expect(uninstalled, isFalse);

              worker.stop();
              expect(logs, doesNotMention('intended failure on uninstall'));
              expect(logs, doesNotMention('service uninstalled successfully'));

              await Future.delayed(TestService.delay * 2);
              expect(logs, mentions('intended failure on uninstall'));
              expect(logs, doesNotMention('service uninstalled successfully'));
            });
          });

          test('- cannot restart after stop', () async {
            final worker = TestWorker(testContext);
            await worker.start();

            await Future.delayed(TestService.shortDelay);
            worker.stop();
            expect(worker.isStopped, isTrue);
            await Future.delayed(TestService.shortDelay);

            try {
              final res = await worker.start();
              throw unexpectedSuccess('start()', res);
            } on WorkerException catch (ex) {
              lowerCaseCheck(ex.message, contains('worker is stopped'));
            }
          });
        });

        group('- workloads', () {
          test('- sequential', () async {
            final worker = TestWorker(testContext);
            await worker.start();

            final completedTasks = <int>[];
            int taskId = 0;

            Future createTask(Duration duration) {
              final id = ++taskId;
              return worker
                  .io(ms: duration.inMilliseconds)
                  .whenComplete(() => completedTasks.add(id));
            }

            expect(completedTasks, isEmpty, reason: 'no tasks yet');
            expect(worker.workload, isZero);
            expect(worker.maxWorkload, isZero);
            expect(worker.totalWorkload, isZero);

            await createTask(TestService.shortDelay); // task #1

            expect(completedTasks, equals([1]), reason: '#1 has completed');
            expect(worker.workload, isZero);
            expect(worker.maxWorkload, equals(1));
            expect(worker.totalWorkload, equals(1));

            var task = createTask(TestService.shortDelay * 5); // task #2

            expect(completedTasks, equals([1]), reason: '#2 pending');
            expect(worker.workload, equals(1));
            expect(worker.maxWorkload, equals(1));
            expect(worker.totalWorkload, equals(1));

            await Future.delayed(TestService.delay);

            expect(completedTasks, equals([1]), reason: '#2 still pending');
            expect(worker.workload, equals(1));
            expect(worker.maxWorkload, equals(1));
            expect(worker.totalWorkload, equals(1));

            await task;

            expect(completedTasks, equals([1, 2]), reason: '#2 has completed');
            expect(worker.workload, isZero);
            expect(worker.maxWorkload, equals(1));
            expect(worker.totalWorkload, equals(2));

            await createTask(TestService.shortDelay); // task #3

            expect(completedTasks, equals([1, 2, 3]),
                reason: '#3 has completed');
            expect(worker.workload, isZero);
            expect(worker.maxWorkload, equals(1));
            expect(worker.totalWorkload, equals(3));

            worker.stop();

            expect(worker.workload, isZero);
            expect(worker.maxWorkload, equals(1));
            expect(worker.totalWorkload, equals(3));
          });

          test('- parallel', () async {
            final worker = TestWorker(testContext);
            await worker.start();

            final completedTasks = <int>[];
            int taskId = 0;

            Future createTask(Duration duration) {
              final id = ++taskId;
              return worker
                  .io(ms: duration.inMilliseconds)
                  .whenComplete(() => completedTasks.add(id));
            }

            await worker.start();

            expect(completedTasks, isEmpty, reason: 'no tasks yet');
            expect(worker.workload, isZero);
            expect(worker.maxWorkload, isZero);
            expect(worker.totalWorkload, isZero);

            var tasks = [
              createTask(TestService.delay), // task 1
              createTask(TestService.delay * 5), // task 2
              createTask(TestService.delay * 3), // task 3
            ];

            expect(completedTasks, isEmpty, reason: 'no async suspension yet');
            expect(worker.workload, equals(3));
            expect(worker.maxWorkload, equals(3));
            expect(worker.totalWorkload, isZero);

            await Future.wait(tasks);

            expect(completedTasks, equals([1, 3, 2]), reason: '#1, #3, #2');
            expect(worker.workload, isZero);
            expect(worker.maxWorkload, equals(3));
            expect(worker.totalWorkload, equals(3));

            completedTasks.clear();

            /////////// time origin for next tasks ///////////

            createTask(TestService.delay * 11); // #4 complete at 11 delays
            createTask(TestService.delay * 7); // #5 complete at 7 delays
            createTask(TestService.delay * 5); // #6 complete at 5 delays

            expect(completedTasks, isEmpty, reason: 'no async suspension yet');
            expect(worker.workload, equals(3));
            expect(worker.maxWorkload, equals(3));
            expect(worker.totalWorkload, equals(3));

            await Future.delayed(
                TestService.delay * 1.5); // 1.5 delay: all tasks still pending

            expect(completedTasks, isEmpty, reason: '1.5 delays');
            expect(worker.workload, equals(3));
            expect(worker.maxWorkload, equals(3));
            expect(worker.totalWorkload, equals(3));

            await Future.delayed(TestService.delay *
                4); // 5.5 delays: tasks #6 finished, #4 & #5 still pending

            expect(completedTasks, equals([6]), reason: '5.5 delays');
            expect(worker.workload, equals(2));
            expect(worker.maxWorkload, equals(3));
            expect(worker.totalWorkload, equals(4));

            createTask(TestService.delay * 5); // #7 complete at 10.5 delays
            createTask(TestService.delay * 3); // #8 complete at 8.5 delays

            expect(completedTasks, equals([6]), reason: 'still 5.5 delays');
            expect(worker.workload, equals(4));
            expect(worker.maxWorkload, equals(4));
            expect(worker.totalWorkload, equals(4));

            await Future.delayed(TestService.delay *
                4); // 9.5 delays: tasks #5 and #8 complete, #4 and #7 still pending

            expect(completedTasks, equals([6, 5, 8]), reason: '9.5 delays');
            expect(worker.workload, equals(2));
            expect(worker.maxWorkload, equals(4));
            expect(worker.totalWorkload, equals(6));

            await Future.delayed(
                TestService.delay * 2.5); // 12 delays: all tasks finished

            expect(completedTasks, equals([6, 5, 8, 7, 4]),
                reason: '12 delays');
            expect(worker.workload, isZero);
            expect(worker.maxWorkload, equals(4));
            expect(worker.totalWorkload, equals(8));

            worker.stop();
            expect(worker.workload, isZero);
            expect(worker.maxWorkload, equals(4));
            expect(worker.totalWorkload, equals(8));
          });
        });

        group('- initialization error', () {
          test('- failed init', () async {
            final worker = TestWorker.throws(testContext);
            try {
              final res = await worker.start();
              throw unexpectedSuccess('start()', res);
            } on SquadronError catch (_) {
              // expected exception
            } catch (ex, st) {
              trace('UNHANDLED EXCEPTION $ex at $st');
              rethrow;
            }

            try {
              final res = await worker.ping();
              throw unexpectedSuccess('ping()', res);
            } on SquadronError catch (_) {
              // expected exception
            } catch (ex, st) {
              trace('UNHANDLED EXCEPTION $ex at $st');
              rethrow;
            }
          });

          test('- missing start request', () async {
            final worker = TestWorker.missingStartRequest(testContext);
            if (worker != null) {
              try {
                final res = await worker.start();
                throw unexpectedSuccess('start()', res);
              } on SquadronError catch (_) {
                // expected exception
              }

              try {
                final res = await worker.ping();
                throw unexpectedSuccess('ping()', res);
              } on SquadronError catch (_) {
                // expected exception
              }
            }
          });

          test('- invalid command ID', () async {
            final worker = TestWorker.invalid(testContext);
            try {
              final res = await worker.start();
              throw unexpectedSuccess('start()', res);
            } on SquadronError catch (_) {
              // expected exception
            }

            try {
              final res = await worker.ping();
              throw unexpectedSuccess('ping()', res);
            } on SquadronError catch (_) {
              // expected exception
            }
          });
        });

        group('- error handling', () {
          late final TestWorker worker;

          setUpAll(() {
            worker = TestWorker(testContext);
            return worker.start();
          });

          tearDownAll(() {
            worker.stop();
          });

          test('- Exception', () async {
            final errors = worker.stats.totalErrors;
            try {
              final res = await worker.throwException();
              throw unexpectedSuccess('throwException()', res);
            } on WorkerException catch (ex) {
              lowerCaseCheck(ex.message, contains('intentional exception'));
              caseCheck(ex.stackTrace, contains('throwException'));
            }
            expect(worker.stats.totalErrors, equals(errors + 1));
          });

          test('- WorkerException', () async {
            final errors = worker.stats.totalErrors;
            try {
              final res = await worker.throwWorkerException();
              // should never happen
              throw unexpectedSuccess('throwWorkerException()', res);
            } on WorkerException catch (ex) {
              lowerCaseCheck(
                  ex.message, equals('intentional worker exception'));
              caseCheck(ex.stackTrace, contains('throwWorkerException'));
            }
            expect(worker.stats.totalErrors, equals(errors + 1));
          });

          test('- TaskTimeOutException', () async {
            final errors = worker.stats.totalErrors;
            try {
              final res = await worker.throwTaskTimeOutException();
              throw unexpectedSuccess('throwTaskTimeOutException()', res);
            } on SquadronTimeoutException catch (ex) {
              lowerCaseCheck(
                  ex.message, contains('intentional timeout exception'));
            }
            expect(worker.stats.totalErrors, equals(errors + 1));
          });

          test('- CanceledException', () async {
            final errors = worker.stats.totalErrors;
            try {
              final res = await worker.throwCanceledException();
              throw unexpectedSuccess('throwCanceledException()', res);
            } on SquadronCanceledException catch (ex) {
              lowerCaseCheck(
                  ex.message, contains('intentional canceled exception'));
            }
            expect(worker.stats.totalErrors, equals(errors + 1));
          });

          test('- CustomException', () async {
            worker.exceptionManager
                .register(CustomException.typeId, CustomException.deserialize);
            try {
              final errors = worker.stats.totalErrors;
              try {
                final res = await worker.throwCustomException();
                throw unexpectedSuccess('throwCustomException()', res);
              } on CustomException catch (ex) {
                lowerCaseCheck(
                    ex.message, contains('intentional custom exception'));
                caseCheck(ex.stackTrace, contains('throwCustomException'));
                expect(ex.command,
                    equals(TestService.throwCustomExceptionCommand));
              }
              expect(worker.stats.totalErrors, equals(errors + 1));
            } finally {
              worker.exceptionManager.unregister(CustomException.typeId);
            }
          });

          test('- invalid request', () async {
            final transferable = [1];
            final result = await worker.forward(transferable);
            expect(result, equals(transferable));

            final obj = getUnsendable();
            try {
              final res = await worker.forward(obj);
              throw unexpectedSuccess('forward()', res);
            } on SquadronError catch (_) {
              // expected error
            }

            // ensure worker is still alive
            final status = await worker.ping();
            expect(status, isTrue);
          });

          test('- invalid response', () async {
            try {
              final res = await worker.invalidResponse();
              throw unexpectedSuccess('invalidResponse()', res);
            } on SquadronError catch (_) {
              // expected error
            }

            // ensure worker is still alive
            final status = await worker.ping();
            expect(status, isTrue);
          });

          test('- missing operation', () async {
            try {
              final res = await worker.missing();
              throw unexpectedSuccess('missing()', res);
            } on SquadronError catch (ex) {
              lowerCaseCheck(ex.message, contains(('unknown command')));
            }

            // ensure worker is still alive
            final status = await worker.ping();
            expect(status, isTrue);
          });
        });

        group('- streaming', () {
          late TestWorker worker;

          setUpAll(() {
            worker = TestWorker(testContext);
            return worker.start();
          });

          tearDownAll(() {
            worker.stop();
          });

          test('- cancelOnError: false', () async {
            final done = Completer();
            final numbers = <int>[];
            final errors = <SquadronException>[];
            final maxErrors = 3;

            var pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, isZero);

            late StreamSubscription sub;
            sub = worker.infiniteWithErrors().listen(
              numbers.add,
              onError: (ex) {
                errors.add(ex);
                if (errors.length >= maxErrors) {
                  sub.cancel();
                  done.complete();
                }
              },
              onDone: done.complete,
              cancelOnError: false,
            );

            pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, equals(1));

            await done.future;

            expect(errors.length, equals(maxErrors));
            expect(numbers.length, greaterThan(errors.length));
            expect(
              errors.every((e) => e.message.toLowerCase().contains('error #')),
              isTrue,
            );

            pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, isZero);
          });

          test('- cancelOnError: true', () async {
            final numbers = <int>[];

            var pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, isZero);

            try {
              final done = worker
                  .infiniteWithErrors()
                  .listen(numbers.add, cancelOnError: true)
                  .asFuture();

              pending = await worker.getPendingInfiniteWithErrors();
              expect(pending, equals(1));
              final res = await done;
              throw unexpectedSuccess('infiniteWithErrors()', res);
            } on WorkerException catch (ex) {
              lowerCaseCheck(ex.message, contains('error #'));
            }

            expect(numbers, equals([0, 1, 2]));

            pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, isZero);
          });

          test('- await for', () async {
            final numbers = <int>[];

            try {
              await for (var number in worker.infiniteWithErrors()) {
                final pending = await worker.getPendingInfiniteWithErrors();
                expect(pending, equals(1));
                numbers.add(number);
              }
              throw unexpectedSuccess('infiniteWithErrors()');
            } on WorkerException catch (ex) {
              lowerCaseCheck(ex.message, contains('error #'));
            }

            expect(numbers, equals([0, 1, 2]));

            final pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, isZero);
          });

          test('- throwing in await for', () async {
            final numbers = <int>[];

            try {
              await for (var number in worker.infiniteWithErrors()) {
                final pending = await worker.getPendingInfiniteWithErrors();
                expect(pending, equals(1));
                if (numbers.isEmpty) {
                  numbers.add(number);
                } else {
                  throw WorkerException('Client-side exception');
                }
              }
              throw unexpectedSuccess('infiniteWithErrors()');
            } on WorkerException catch (ex) {
              caseCheck(ex.message, equals('Client-side exception'));
            }

            expect(numbers, equals([0]));

            final pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, isZero);
          });

          test('- pause/resume', () async {
            var pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, isZero);

            final numbers = <int>[];
            final errors = <SquadronException>[];

            final sub = worker
                .infiniteWithErrors()
                .listen(numbers.add, onError: errors.add, cancelOnError: false);

            int countNumbers = 0;
            int countErrors = 0;
            int paused = 0;

            void pause() {
              sub.pause();
              if (paused == 0) {
                expect(numbers.length, greaterThan(countNumbers));
                expect(errors.length, greaterThan(countErrors));
                countNumbers = numbers.length;
                countErrors = errors.length;
              } else {
                expect(numbers.length, equals(countNumbers));
                expect(errors.length, equals(countErrors));
              }
              paused++;
            }

            void resume() {
              expect(numbers.length, equals(countNumbers));
              expect(errors.length, equals(countErrors));
              sub.resume();
              if (paused > 0) {
                paused--;
              }
            }

            // this call should have no effect
            sub.resume();

            // pause immediately
            sub.pause();
            expect(numbers, isEmpty);
            expect(errors, isEmpty);
            await Future.delayed(TestService.delay * 3);
            expect(numbers, isEmpty);
            expect(errors, isEmpty);
            // resume
            sub.resume();

            await Future.delayed(TestService.delay * 3);
            pause();
            pause();
            await Future.delayed(TestService.delay * 3);
            resume();
            await Future.delayed(TestService.delay * 3);
            resume();
            await Future.delayed(TestService.delay * 3);

            sub.cancel();

            expect(numbers.length, greaterThan(countNumbers));
            expect(errors.length, greaterThan(countErrors));
            expect(errors.map((e) => e.message.toLowerCase()),
                doesNotMention('by request'));

            await Future.delayed(TestService.delay);

            pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, isZero);
          });

          test('- immediate cancelation', () async {
            var pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, isZero);

            final numbers = <int>[];
            final errors = <SquadronException>[];

            final sub = worker
                .infiniteWithErrors()
                .listen(numbers.add, onError: errors.add, cancelOnError: false);

            sub.cancel();

            await Future.delayed(TestService.delay * 3);

            expect(numbers, isEmpty);
            expect(errors, isEmpty);

            pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, isZero);
          });

          test('- subscription cancelation', () async {
            var counter = 0;
            final clock = worker.clock(frequency: 100);
            final sub = clock.listen((n) {
              counter++;
            });
            await Future.delayed(Duration(milliseconds: 100));
            expect(counter, isPositive);
            sub.cancel();
            worker.stop();
          });
        });

        group('- sharing wokers', () {
          test('- cache worker', () async {
            final cache = CacheWorker(testContext);

            expect(await cache.get(1), isNull);
            expect(await cache.containsKey(1), isFalse);
            await cache.set(1, 'in cache');
            expect(await cache.containsKey(1), isTrue);
            expect(await cache.get(1), equals('in cache'));

            cache.stop();
            expect(cache.isStopped, isTrue);
          });

          test('- prime worker with cache', () async {
            final cache = CacheWorker(testContext);
            await cache.start();

            var cacheStats = await cache.getStats();
            expect(cacheStats.hit, isZero);
            expect(cacheStats.miss, isZero);
            expect(cacheStats.expired, isZero);
            expect(cacheStats.size, isZero);
            expect(cacheStats.maxSize, isZero);

            final primeWorker = PrimeWorker(testContext, cache);

            final sw = Stopwatch()..start();
            for (var prime in largePrimes) {
              expect(await primeWorker.isPrime(prime), isTrue);
            }
            final elapsedWithEmptyCache = sw.elapsedMicroseconds;

            cacheStats = await cache.getStats();
            expect(cacheStats.hit, isZero);
            expect(cacheStats.miss, isPositive);
            expect(cacheStats.expired, isZero);
            expect(cacheStats.size, isPositive);
            expect(cacheStats.maxSize, equals(cacheStats.size));

            sw.reset();
            for (var prime in largePrimes) {
              expect(await primeWorker.isPrime(prime), isTrue);
            }
            final elapsedWithFullCache = sw.elapsedMicroseconds;

            cacheStats = await cache.getStats();
            expect(cacheStats.hit, isPositive);
            expect(cacheStats.miss, isPositive);
            expect(cacheStats.hit, equals(cacheStats.miss));
            expect(cacheStats.expired, isZero);
            expect(cacheStats.size, isPositive);
            expect(cacheStats.maxSize, equals(cacheStats.size));

            expect(elapsedWithFullCache, lessThan(elapsedWithEmptyCache / 5));

            primeWorker.stop();
            expect(primeWorker.isStopped, isTrue);

            cache.stop();
            expect(cache.isStopped, isTrue);
          });
        });
      });
    });