// ignore_for_file: file_names

import 'package:test/test.dart';
import 'package:using/using.dart';

import 'src/test_context.dart';
import 'worker_services/cache_service_worker.dart';
import 'worker_services/prime_service_worker.dart';
import 'worker_services/primes.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '07_shared_channel_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- SHARED CHANNEL', () {
      tc.test('- Standalone cache worker', () async {
        await CacheWorker(tc).useAsync((cache) async {
          expect(await cache.get(1), isNull);
          expect(await cache.containsKey(1), isFalse);
          await cache.set(1, 'in cache');
          expect(await cache.containsKey(1), isTrue);
          expect(await cache.get(1), 'in cache');
        });
      });

      tc.test('- Prime worker + cache worker', () async {
        await CacheWorker(tc).useAsync((cache) async {
          await cache.start();

          var cacheStats = await cache.getCacheStats();
          expect(cacheStats.hit, isZero);
          expect(cacheStats.miss, isZero);
          expect(cacheStats.expired, isZero);
          expect(cacheStats.size, isZero);
          expect(cacheStats.maxSize, isZero);

          await PrimeWorker(tc, cache).useAsync((w) async {
            final sw = Stopwatch()..start();
            for (var prime in largePrimes) {
              expect(await w.isPrime(prime), isTrue);
            }
            final elapsedWithEmptyCache = sw.elapsedMicroseconds;

            cacheStats = await cache.getCacheStats();
            final cacheSize = cacheStats.size;
            expect(cacheSize, isPositive);
            expect(cacheStats.hit, isZero);
            expect(cacheStats.miss, cacheSize);
            expect(cacheStats.expired, isZero);
            expect(cacheStats.maxSize, cacheSize);

            sw.reset();
            for (var prime in largePrimes) {
              expect(await w.isPrime(prime), isTrue);
            }
            final elapsedWithFullCache = sw.elapsedMicroseconds;

            cacheStats = await cache.getCacheStats();
            expect(cacheStats.hit, cacheSize);
            expect(cacheStats.miss, cacheSize);
            expect(cacheStats.expired, isZero);
            expect(cacheStats.size, cacheSize);
            expect(cacheStats.maxSize, cacheSize);

            expect(elapsedWithFullCache, lessThan(elapsedWithEmptyCache / 2));
          });
        });
      });
    });
  });
}
