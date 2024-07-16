@TestOn('vm || browser')
library;

import 'package:test/test.dart';

import 'classes/prime_numbers.dart';
import 'classes/test_context.dart';
import 'worker_services/cache_service_worker.dart';
import 'worker_services/prime_service_worker.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

String testScript = 'shared_channel_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    tc.group("- Shared Channel", () {
      tc.test('- cache worker', () async {
        final cache = CacheWorker(tc);

        expect(await cache.get(1), isNull);
        expect(await cache.containsKey(1), isFalse);
        await cache.set(1, 'in cache');
        expect(await cache.containsKey(1), isTrue);
        expect(await cache.get(1), equals('in cache'));

        cache.stop();
        expect(cache.isStopped, isTrue);
      });

      tc.test('- prime worker with cache', () async {
        final cache = CacheWorker(tc);
        await cache.start();

        var cacheStats = await cache.getStats();
        expect(cacheStats.hit, isZero);
        expect(cacheStats.miss, isZero);
        expect(cacheStats.expired, isZero);
        expect(cacheStats.size, isZero);
        expect(cacheStats.maxSize, isZero);

        final primeWorker = PrimeWorker(tc, cache);

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
}
